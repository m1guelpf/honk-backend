import SQLiteData
import Foundation
import Hummingbird
import Dependencies
import HummingbirdRouter

struct OnboardingController: RouterController {
	var body: some RouterMiddleware<Context> {
		RequireAuthToken()

		Post("reserve", handler: reserveUsername)
		Post("users", handler: registerUser)
	}

	@Dependency(\.date.now) var now
	@Dependency(\.defaultDatabase) var database

	/// Check wether the given username is available and, if so, reserve it for the user making the request.
	///
	/// - Note: We don't currently hold reservations, as the scale of this reconstruction should be small enough to avoid frontrunning issues.
	func reserveUsername(_ request: Request, context: Context) async throws -> MessageResponse {
		let request = try await request.decode(as: ReserveRequest.self, context: context)

		guard try REGEX_VALID_USERNAME.wholeMatch(in: request.username) != nil else {
			throw ErrorResponse(.unprocessableContent, code: "usernameInvalid", message: "That username isn't valid.")
		}

		guard let usernameTaken = try await database.read({ db in
			try Values(User.where { $0.username.eq(request.username) }.exists()).fetchOne(db)
		}), !usernameTaken else {
			throw ErrorResponse(.conflict, code: "usernameTaken", message: "That username is taken.")
		}

		return MessageResponse(message: "Username is available.")
	}

	func registerUser(_ request: Request, context: Context) async throws -> RawAuthResponse {
		let authToken = try context.requireAuthToken()
		let body = try await request.decode(as: CreateUserRequest.self, context: context)

		guard try REGEX_VALID_USERNAME.wholeMatch(in: body.username) != nil else {
			throw ErrorResponse(.unprocessableContent, code: "invalid", message: "That username isn't valid.")
		}

		guard let usernameTaken = try await database.read({ db in
			try Values(User.where { $0.username.eq(body.username) }.exists()).fetchOne(db)
		}), !usernameTaken else {
			throw ErrorResponse(.conflict, code: "taken", message: "That username is taken.")
		}

		guard let birthday = try? Date(dateOfBirth: body.dateOfBirth) else {
			throw ErrorResponse(.unprocessableContent, code: "invalid", message: "That date of birth isn't valid.")
		}

		let contactHash = FirebaseTokenVerifier.pendingHashes.withLock { $0.removeValue(forKey: authToken.sub.value) }

		guard let user = try await database.write({ db in
			try User.insert {
				User(
					id: body.uid,
					firebaseUid: authToken.sub.value,
					username: body.username,
					name: body.name,
					avatarUrl: URL(string: "https://firebasestorage.googleapis.com/v0/b/honkreloaded.firebasestorage.app/o/system%2Fdefault-avatar.png?alt=media")!,
					birthday: birthday,
					contactHash: contactHash,
					createdAt: now,
					updatedAt: now
				)
			}
			.returning(\.self)
			.fetchOne(db)
		}) else { throw HTTPError(.internalServerError, message: "Failed to create user.") }

		return RawAuthResponse(
			token: request.headers.bearer!.token,
			expiresAt: authToken.exp.value,
			user: RawUserAccountInfo(user, compliments: [:], shouldForceReloadFriends: true)
		)
	}
}
