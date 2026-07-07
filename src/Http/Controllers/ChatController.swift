import Foundation
import SQLiteData
import Hummingbird
import Dependencies
import HummingbirdRouter

struct ChatController: RouterController {
	var body: some RouterMiddleware<AuthContext> {
		RouteGroup("chat") {
			Get("friends", handler: getChats)
		}
	}

	@Dependency(\.date.now) var now
	@Dependency(\.defaultDatabase) var database

	func getChats(_ request: Request, context: AuthContext) async throws -> FriendChatsResponse {
		_ = try request.uri.decodeQuery(as: FriendChatsQuery.self, context: context)
		let me = context.user

		let chats = try await database.read { db -> [APIFriendConversation] in
			let friendIds = try Friendship
				.where { $0.state.eq(Friendship.State.accepted) && $0.involves(me.id) }
				.order { ($0.lastActivityAt.desc(), $0.id) }
				.select { $0.friendId(besides: me.id) }
				.fetchAll(db)

			// TODO: fill theirMessage/yourMessage/dates from the messages table once messaging exists.
			return friendIds.map { friendId in
				APIFriendConversation(friendId: friendId, theirMessage: nil, yourMessage: nil, theirDate: nil, yourDate: nil)
			}
		}

		return FriendChatsResponse(chats: chats)
	}
}
