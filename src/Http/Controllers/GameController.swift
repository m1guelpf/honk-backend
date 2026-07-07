import Foundation
import SQLiteData
import Hummingbird
import Dependencies
import HummingbirdRouter

struct GameController: RouterController {
	var body: some RouterMiddleware<AuthContext> {
		RouteGroup("game") {
			// TODO: Catch-all route might shadow some other /game endpoints, keep an eye out

			Get(":friendshipId", handler: getGame)
		}
	}

	@Dependency(\.defaultDatabase) var database

	func getGame(_: Request, context: AuthContext) async throws -> APIGameModel? {
		guard let friendshipId = context.parameters.get("friendshipId") else { throw HTTPError(.badRequest) }
		let me = context.user

		// TODO: this can be optimized to one query later
		let (game, friendship) = try await database.read { db in
			let friendship = try Friendship
				.where { $0.id.eq(friendshipId) && $0.involves(me.id) }
				.fetchOne(db)
			guard let friendship else { throw HTTPError(.notFound) }

			let game = try Game
				.where { $0.friendshipId.eq(friendshipId) } // TODO: exclude base on `status` once we know its possible values
				.order { $0.createdAt.desc() }
				.fetchOne(db)

			return (game, friendship)
		}

		guard let game else { return nil }
		return APIGameModel(from: game, friendship: friendship)
	}
}
