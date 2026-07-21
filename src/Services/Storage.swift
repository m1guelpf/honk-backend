import JWTKit
import NIOCore
import Foundation
import Hummingbird
import Dependencies
import Synchronization
import DependenciesMacros
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public actor FirebaseStorage {
	public enum Error: Swift.Error, Sendable {
		case invalidConfiguration(String)
		case invalidResponse(response: URLResponse)
	}

	private struct ServiceAccount: Decodable {
		let tokenURI: URL
		let privateKey: String
		let clientEmail: String

		enum CodingKeys: String, CodingKey {
			case tokenURI = "token_uri"
			case privateKey = "private_key"
			case clientEmail = "client_email"
		}
	}

	public struct UploadedObject: Decodable, Sendable {
		public let name: String
		public let size: String
		public let bucket: String
		public let generation: String
	}

	private let tokenURI: URL
	private let bucket: String
	private let clientEmail: String
	private let session: URLSession
	private let keys: JWTKeyCollection

	private var cachedToken: AccessToken?

	public init(serviceAccountJSON: String, bucket: String, session: URLSession = .shared) async throws {
		let account = try JSONDecoder().decode(ServiceAccount.self, from: Data(serviceAccountJSON.utf8))

		self.bucket = bucket
		self.session = session
		tokenURI = account.tokenURI
		clientEmail = account.clientEmail
		keys = try await JWTKeyCollection().add(rsa: Insecure.RSA.PrivateKey(pem: account.privateKey), digestAlgorithm: .sha256)
	}

	public func upload(_ bytes: ByteBuffer, as objectName: String, contentType: String = "application/octet-stream") async throws -> UploadedObject {
		guard let encodedName = objectName.addingPercentEncoding(withAllowedCharacters: Self.rfc3986Unreserved) else {
			throw Error.invalidConfiguration("Object name could not be percent-encoded")
		}

		let token = try await accessToken()
		let data = Data(bytes.readableBytesView)

		var request = URLRequest(
			url: URL(string: "https://storage.googleapis.com/upload/storage/v1/b/\(bucket)/o?uploadType=media&name=\(encodedName)")!
		)
		request.httpBody = data
		request.httpMethod = "POST"
		request.setValue(contentType, forHTTPHeaderField: "Content-Type")
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")

		let (responseData, response) = try await session.data(for: request)
		guard let http = response as? HTTPURLResponse else { throw Error.invalidResponse(response: response) }

		guard (200 ..< 300).contains(http.statusCode) else {
			throw HTTPError(.init(integerLiteral: http.statusCode), message: Self.googleErrorMessage(data) ?? "Upload failed")
		}

		return try JSONDecoder().decode(UploadedObject.self, from: responseData)
	}

	public func download(at path: String) async throws -> Data {
		guard let encodedName = path.addingPercentEncoding(withAllowedCharacters: Self.rfc3986Unreserved) else {
			throw Error.invalidConfiguration("Object name could not be percent-encoded")
		}

		let token = try await accessToken()

		var request = URLRequest(url: URL(string: "https://storage.googleapis.com/storage/v1/b/\(bucket)/o/\(encodedName)?alt=media")!)
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

		let (data, response) = try await session.data(for: request)
		guard let http = response as? HTTPURLResponse else { throw Error.invalidResponse(response: response) }

		if http.statusCode == 404 { throw HTTPError(.notFound, message: "Not Found") }
		guard (200 ..< 300).contains(http.statusCode) else {
			throw HTTPError(.init(integerLiteral: http.statusCode), message: Self.googleErrorMessage(data) ?? "Download failed")
		}

		return data
	}

	public func delete(at path: String) async throws {
		guard let encodedName = path.addingPercentEncoding(withAllowedCharacters: Self.rfc3986Unreserved) else {
			throw Error.invalidConfiguration("Object name could not be percent-encoded")
		}

		let token = try await accessToken()

		var request = URLRequest(url: URL(string: "https://storage.googleapis.com/storage/v1/b/\(bucket)/o/\(encodedName)")!)
		request.httpMethod = "DELETE"
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

		let (data, response) = try await session.data(for: request)
		guard let http = response as? HTTPURLResponse else { throw Error.invalidResponse(response: response) }

		guard (200 ..< 300).contains(http.statusCode) || http.statusCode == 404 else {
			throw HTTPError(.init(integerLiteral: http.statusCode), message: Self.googleErrorMessage(data) ?? "Delete failed")
		}
	}

	// MARK: - Helpers

	private static let rfc3986Unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

	private static func googleErrorMessage(_ data: Data) -> String? {
		struct GoogleError: Decodable {
			struct Payload: Decodable { let message: String }
			let error: Payload
		}

		return try? JSONDecoder().decode(GoogleError.self, from: data).error.message
	}
}

// MARK: - Authentication

extension FirebaseStorage {
	private struct OAuthAssertion: JWTPayload {
		let iat: Int
		let exp: Int
		let iss: String
		let aud: String
		let scope: String

		func verify(using _: some JWTAlgorithm) throws {}
	}

	private struct TokenResponse: Decodable {
		let expires_in: Int
		let access_token: String
	}

	private struct AccessToken {
		let value: String
		let expiresAt: Date
	}

	private func accessToken() async throws -> String {
		@Dependency(\.date.now) var now

		if let cachedToken, cachedToken.expiresAt.timeIntervalSince(now) > 60 {
			return cachedToken.value
		}

		let issuedAt = Int(now.timeIntervalSince1970)
		let assertion = try await keys.sign(
			OAuthAssertion(
				iat: issuedAt,
				exp: issuedAt + 3600,
				iss: clientEmail,
				aud: tokenURI.absoluteString,
				scope: "https://www.googleapis.com/auth/devstorage.read_write"
			)
		)

		var request = URLRequest(url: tokenURI)
		request.httpMethod = "POST"
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		request.httpBody = Data("grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=\(assertion)".utf8)

		let (data, response) = try await session.data(for: request)
		guard let http = response as? HTTPURLResponse else { throw Error.invalidResponse(response: response) }

		guard (200 ..< 300).contains(http.statusCode) else {
			throw HTTPError(.init(integerLiteral: http.statusCode), message: Self.googleErrorMessage(data) ?? "Token request failed")
		}

		let token = try JSONDecoder().decode(TokenResponse.self, from: data)
		cachedToken = AccessToken(value: token.access_token, expiresAt: now.addingTimeInterval(TimeInterval(token.expires_in)))

		return token.access_token
	}
}

// MARK: - Dependency

@DependencyClient
struct StorageClient: Sendable {
	var upload: @Sendable (_ bytes: ByteBuffer, _ path: String, _ contentType: String) async throws -> FirebaseStorage.UploadedObject
	var download: @Sendable (_ path: String) async throws -> Data
	var delete: @Sendable (_ path: String) async throws -> Void
}

extension StorageClient: DependencyKey {
	static let liveValue = StorageClient(
		upload: { bytes, path, contentType in
			try await sharedFirebaseStorage().upload(bytes, as: path, contentType: contentType)
		},
		download: { path in
			try await sharedFirebaseStorage().download(at: path)
		},
		delete: { path in
			try await sharedFirebaseStorage().delete(at: path)
		}
	)
}

extension DependencyValues {
	var storage: StorageClient {
		get { self[StorageClient.self] }
		set { self[StorageClient.self] = newValue }
	}
}

private let sharedStorage = Mutex<Task<FirebaseStorage, any Error>?>(nil)

private func sharedFirebaseStorage() async throws -> FirebaseStorage {
	let task = sharedStorage.withLock { box -> Task<FirebaseStorage, any Error> in
		if let box { return box }

		let task = Task {
			@Dependency(\.config) var config
			return try await FirebaseStorage(
				serviceAccountJSON: config.requiredString(forKey: "firebase.serviceAccount", isSecret: true),
				bucket: config.requiredString(forKey: "firebase.bucket")
			)
		}

		box = task
		return task
	}

	do {
		return try await task.value
	} catch {
		sharedStorage.withLock { $0 = nil }
		throw error
	}
}
