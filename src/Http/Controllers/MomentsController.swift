import Foundation
import SQLiteData
import Hummingbird
import Dependencies
import HummingbirdRouter

struct MomentsController: RouterController {
	var body: some RouterMiddleware<AuthContext> {
		Get("moment/:chatId", handler: getChatMoments)
	}

	@Dependency(\.date.now) var now
	@Dependency(\.defaultDatabase) var database

	func getChatMoments(_ request: Request, context: AuthContext) async throws -> MomentsResponse {
		guard let chatId = context.parameters.get("chatId") else { throw HTTPError(.badRequest) }
		let query = try request.uri.decodeQuery(as: PaginationQuery.self, context: context)
		let me = context.user

		let moments = try await database.read { db in
			try Conversation.find(chatId)
				.join(Friendship.all) { $1.id.eq($0.friendshipId) && $1.involves(me.id) }
				.join(Moment.all) { $2.friendshipId.eq($1.id) }
				.limit(query.limit, offset: query.offset)
				.select { $2 }
				.fetchAll(db)
		}

		return MomentsResponse(moments: moments.map { APIMoment(from: $0) })
	}
}
