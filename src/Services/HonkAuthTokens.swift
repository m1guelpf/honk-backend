import JWTKit
import Foundation
import Dependencies

struct HonkAuthTokens: Sendable {
	struct AuthToken: JWTPayload {
		var sub: SubjectClaim
		var exp: ExpirationClaim

		init(sub: String, exp: Date) {
			self.sub = SubjectClaim(value: sub)
			self.exp = ExpirationClaim(value: exp)
		}

		func verify(using _: some JWTAlgorithm) throws {
			@Dependency(\.date.now) var now

			try exp.verifyNotExpired(currentDate: now)
		}
	}

	private let keys = JWTKeyCollection()
	private let keyFactory: @Sendable () async throws -> HMACKey

	private init(keyFactory: @escaping @Sendable () async throws -> HMACKey) {
		self.keyFactory = keyFactory
	}

	func generate(for userID: String) async throws -> (String, AuthToken) {
		@Dependency(\.date.now) var now

		try await ensureKey()

		let payload = AuthToken(sub: userID, exp: now.adding(.weeks(1)))

		return try (await keys.sign(payload), payload)
	}

	func validate(token: String) async throws -> AuthToken {
		try await ensureKey()

		return try await keys.verify(token, as: AuthToken.self)
	}

	private func ensureKey() async throws {
		do {
			_ = try await keys.getKey()
		} catch let error as JWTError {
			guard case .noKeyProvided = error.errorType else { throw error }

			try await keys.add(hmac: await keyFactory(), digestAlgorithm: .sha256)
		} catch {
			throw error
		}
	}
}

// MARK: - Dependencies

extension HonkAuthTokens: DependencyKey {
	static let liveValue = HonkAuthTokens {
		@Dependency(\.config) var config
		return try await HMACKey(from: config.fetchRequiredString(forKey: "jwt.key", isSecret: true))
	}

	static let testValue = HonkAuthTokens { HMACKey(from: "secret") }
}

extension DependencyValues {
	var authTokens: HonkAuthTokens {
		get { self[HonkAuthTokens.self] }
		set { self[HonkAuthTokens.self] = newValue }
	}
}
