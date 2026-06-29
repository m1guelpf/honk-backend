import SQLiteData
import Foundation
import Hummingbird
import Dependencies
import HummingbirdRouter

struct UsersController: RouterController {
	var body: some RouterMiddleware<AuthContext> {
		Get("users/blocked", handler: blockedUsers)
		Get("users/:userId", handler: getUser)
		Put("users/:userId", handler: updateUser)
		Delete("users/:userId", handler: deleteUser)
	}

	@Dependency(\.date.now) var now
	@Dependency(\.defaultDatabase) var database

	func blockedUsers(_: Request, context: AuthContext) async throws -> [String] {
		return try await database.read { db in
			try Block.where { $0.id.blockerId.eq(context.user.id) }.select { $0.id.blockedId }.fetchAll(db)
		}
	}

	func getUser(_: Request, context: AuthContext) throws -> UserResponse {
		guard let userId = context.parameters.get("userId") else { throw HTTPError(.badRequest) }
		guard context.user.id == userId else { throw HTTPError(.forbidden, message: "You can only fetch your own user data.") }

		// TODO: Fetch compliments for the user?
		return UserResponse(user: APIUserInfo(context.user, compliments: [:], shouldForceReloadFriends: false))
	}

	func updateUser(_ request: Request, context: AuthContext) async throws -> UserResponse {
		guard let userId = context.parameters.get("userId") else { throw HTTPError(.badRequest) }
		guard context.user.id == userId else { throw HTTPError(.forbidden, message: "You can only fetch your own user data.") }

		let patch = try await request.decode(as: AccountUpdateRequest.self, context: context)

		guard let user = try await database.write({ db in
			try User.find(context.user.id).update(apply: patch).returning(\.self).fetchOne(db)
		}) else { throw HTTPError(.internalServerError, message: "Failed to update user.") }

		// TODO: Fetch compliments for the user?
		return UserResponse(user: APIUserInfo(user, compliments: [:], shouldForceReloadFriends: false))
	}

	func deleteUser(_: Request, context: AuthContext) async throws -> HTTPResponse.Status {
		guard let userId = context.parameters.get("userId") else { throw HTTPError(.badRequest) }
		guard context.user.id == userId else { throw HTTPError(.forbidden, message: "You can only delete your own account.") }

		try await database.write { db in
			try User.find(context.user.id).delete().execute(db)
			try ContactHash.where { $0.id.userFirebaseUid.eq(context.user.firebaseUid) }.delete().execute(db)
		}

		// TODO: Figure out format
		return .ok
	}
}
