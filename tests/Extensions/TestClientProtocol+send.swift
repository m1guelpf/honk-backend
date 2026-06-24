import Foundation
import Hummingbird
@testable import HonkBackend
import HummingbirdTesting

fileprivate let encoder = JSONEncoder()
fileprivate let allocator = ByteBufferAllocator()

extension TestClientProtocol {
	func send<Return>(
		_ method: HTTPRequest.Method,
		to path: String,
		auth: TestAuthentication? = nil,
		headers: HTTPFields = [:],
		body: ByteBuffer? = nil,
		then: @escaping (TestResponse) async throws -> Return = { $0 }
	) async throws {
		let authHeaders = auth.map { $0.apply(headers: headers) }
		try await execute(uri: path, method: method, headers: authHeaders ?? headers, body: body, testCallback: then)
	}

	func send<T: Encodable, Return>(
		_ method: HTTPRequest.Method,
		to path: String,
		auth: TestAuthentication? = nil,
		headers: HTTPFields = [:],
		body: T,
		then: @escaping (TestResponse) async throws -> Return = { $0 }
	) async throws {
		encoder.dateEncodingStrategy = .honk
		let authHeaders = auth.map { $0.apply(headers: headers) }
		let body = try encoder.encodeAsByteBuffer(body, allocator: allocator)

		try await execute(
			uri: path,
			method: method,
			headers: (authHeaders ?? headers).appending(.init(name: .contentType, value: "application/json")),
			body: body,
			testCallback: then
		)
	}

	func get<Return>(
		_ path: String,
		auth: TestAuthentication? = nil,
		headers: HTTPFields = [:],
		then: @escaping (TestResponse) async throws -> Return = { $0 }
	) async throws {
		try await send(.get, to: path, auth: auth, headers: headers, then: then)
	}

	func post<T: Encodable, Return>(
		_ path: String,
		auth: TestAuthentication? = nil,
		body: T,
		headers: HTTPFields = [:],
		then: @escaping (TestResponse) async throws -> Return = { $0 }
	) async throws {
		try await send(.post, to: path, auth: auth, headers: headers, body: body, then: then)
	}
}

// MARK: - Authentication

public enum TestAuthentication: Equatable {
	case bearer(String)

	func apply(headers: HTTPFields) -> HTTPFields {
		switch self {
			case let .bearer(token):
				var headers = headers
				headers[.authorization] = "Bearer \(token)"
				return headers
		}
	}
}
