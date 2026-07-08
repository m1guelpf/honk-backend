import Foundation
import SQLiteData
import Hummingbird
import Dependencies
import HummingbirdRouter

struct AuthController: RouterController {
	var body: some RouterMiddleware<Context> {
		Post("login/token", handler: loginWithToken)
	}

	@Dependency(\.authTokens) var authTokens
	@Dependency(\.defaultDatabase) var database
	@Dependency(\.firebaseVerifier) var firebase

	func loginWithToken(_ request: Request, context: Context) async throws -> AuthenticationResponse {
		let request = try await request.decode(as: LoginWithTokenRequest.self, context: context)

		guard !request.isTestToken else {
			throw ErrorResponse(.badRequest, code: "malformedRequest", message: "Test tokens are not currently supported.")
		}

		let firebaseToken = try await firebase.verify(token: request.token)

		let (user, compliments) = try await database.read { db -> (User?, [String: Int]) in
			guard let user = try User.where({ $0.id.eq(firebaseToken.userID) }).fetchOne(db)
			else { return (nil, [:]) }

			return try (user, Compliment.counts(for: [user.id], in: db)[user.id] ?? [:])
		}

		if let phoneNumber = firebaseToken.phoneNumber {
			if let user, user.contactHash != nil {
				try await database.write { db in
					try User.find(user.id).update { $0.contactHash = #bind(phoneNumber.contactHash) }.execute(db)
				}
			} else {
				FirebaseTokenVerifier.pendingHashes.withLock { $0[firebaseToken.userID] = phoneNumber.contactHash }
			}
		}

		let (authToken, payload) = try await authTokens.generate(for: firebaseToken.userID)

		return AuthenticationResponse(
			token: authToken,
			expiresAt: payload.exp.value,
			user: user.map { APIUserInfo($0, compliments: compliments, shouldForceReloadFriends: true) }
		)
	}
}
