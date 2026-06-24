import SQLiteData
import Foundation
import Hummingbird
import Dependencies
import HummingbirdRouter

struct UsersController: RouterController {
	var body: some RouterMiddleware<AuthContext> {
		Get("users/:userId", handler: getUser)
	}

	@Dependency(\.date.now) var now
	@Dependency(\.defaultDatabase) var database

	func getUser(_: Request, context: AuthContext) async throws -> RawUserAccountInfo {
		guard let userId = context.parameters.get("userId") else { throw HTTPError(.badRequest) }

		guard let user = try await database.read({ db in
			try User.find(userId).fetchOne(db)
		}) else { throw HTTPError(.notFound, message: "User not found.") }

		// TODO: Fetch compliments for the user?
		return RawUserAccountInfo(user, compliments: [:], shouldForceReloadFriends: false)
	}
}
