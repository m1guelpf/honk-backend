import JWTKit
import Foundation
import Dependencies
import Synchronization
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

fileprivate let decoder = JSONDecoder()
fileprivate let firebaseKeys: Mutex<JWKS?> = Mutex(nil)

struct FirebaseTokenVerifier {
	let keys: @Sendable () async throws -> JWTKeyCollection

	private init(keys: @escaping @Sendable () async throws -> JWTKeyCollection) {
		self.keys = keys
	}

	func verify(token: String) async throws -> FirebaseAuthIdentityToken {
		let token = try await keys().verify(token, as: FirebaseAuthIdentityToken.self)

		@Dependency(\.config) var config
		let applicationIdentifier = try config.requiredString(forKey: "firebase.appIdentifier")

		try token.audience.verifyIntendedAudience(includes: applicationIdentifier)
		guard token.audience.value.first == applicationIdentifier else {
			throw JWTError.claimVerificationFailure(
				failedClaim: token.audience,
				reason: "Audience claim does not match expected value"
			)
		}

		guard token.issuer.value == "https://securetoken.google.com/\(applicationIdentifier)" else {
			throw JWTError.claimVerificationFailure(
				failedClaim: token.issuer,
				reason: "Issuer claim does not match expected value"
			)
		}

		return token
	}

	private static func fetchKeys() async throws -> JWKS {
		if let cached = firebaseKeys.withLock({ $0 }) { return cached }

		let (data, res) = try await URLSession.shared.data(from: URL(string: "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com")!)
		guard let res = res as? HTTPURLResponse, res.statusCode == 200 else {
			throw JWTError.generic(identifier: "firebase-invalid-response", reason: "Failed to fetch keys from Firebase")
		}

		let keys = try decoder.decode(JWKS.self, from: data)
		firebaseKeys.withLock { $0 = keys }
		return keys
	}
}

// MARK: - Dependency

extension FirebaseTokenVerifier: DependencyKey {
	static let liveValue = FirebaseTokenVerifier(keys: {
		try await JWTKeyCollection().add(jwks: await FirebaseTokenVerifier.fetchKeys())
	})

	static let testValue = FirebaseTokenVerifier(keys: {
		await JWTKeyCollection().add(hmac: "secret", digestAlgorithm: .sha256)
	})
}

extension DependencyValues {
	var firebaseVerifier: FirebaseTokenVerifier {
		get { self[FirebaseTokenVerifier.self] }
		set { self[FirebaseTokenVerifier.self] = newValue }
	}
}
