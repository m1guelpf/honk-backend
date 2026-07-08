import Foundation
import SQLiteData
import Hummingbird
import Dependencies
import HummingbirdRouter

struct ChatController: RouterController {
	var body: some RouterMiddleware<AuthContext> {
		RouteGroup("chat") {
			Get("friends", handler: getChats)
			Put(":chatId", handler: updateChat)
			Post(":userId", handler: saveMessage)
			Get(":userId/messages", handler: getMessages)
			Get(":userId/friendship", handler: getFriendship)
			Post(":chatId/magicWords", handler: updateMagicWords)
		}
	}

	@Dependency(\.date.now) var now
	@Dependency(\.defaultDatabase) var database

	func getChats(_ request: Request, context: AuthContext) async throws -> FriendChatsResponse {
		let query = try request.uri.decodeQuery(as: FriendChatsQuery.self, context: context)
		let me = context.user

		let chats = try await database.read { db in
			let rows = try Friendship
				.group(by: \.id)
				.where { $0.state.eq(Friendship.State.accepted) && $0.involves(me.id) }
				.join(Conversation.all) { $1.friendshipId.eq($0.id) }
				.leftJoin(Message.all) { $2.id.conversationId.eq($1.id) }
				.order(by: { friendship, conversation, _ in (conversation.lastActivityAt.desc(), friendship.id) })
				.select { ChatRows.Columns(friendId: $0.friendId(besides: me.id), messages: $2.jsonGroupArray()) }
				.fetchAll(db)

			return rows.map { row in
				let userMessage = row.messages.first(where: { $0.id.senderId == me.id })
				let friendMessage = row.messages.first(where: { $0.id.senderId != me.id })

				return APIFriendConversation(
					friendId: row.friendId,
					theirMessage: friendMessage,
					yourMessage: query.includeYourMessages ? userMessage : nil
				)
			}
		}

		return FriendChatsResponse(chats: chats)
	}

	func getMessages(_ request: Request, context: AuthContext) async throws -> APIFriendConversation {
		guard let userId = context.parameters.get("userId") else { throw HTTPError(.badRequest) }

		let query = try request.uri.decodeQuery(as: ConversationMessagesQuery.self, context: context)
		let me = context.user

		return try await database.read { db in
			let messages = try Friendship
				.where { $0.involves(me.id) && $0.involves(userId) && $0.state.eq(Friendship.State.accepted) }
				.join(Conversation.all) { $1.friendshipId.eq($0.id) }
				.join(Message.all) { $2.id.conversationId.eq($1.id) }
				.group(by: { $2.id })
				.select { $2 }
				.fetchAll(db)

			let theirMessage = messages.first(where: { $0.id.senderId == userId })
			let yourMessage = query.includeYourMessage
				? messages.first(where: { $0.id.senderId == me.id })
				: nil

			return APIFriendConversation(
				friendId: userId,
				theirMessage: theirMessage,
				yourMessage: yourMessage
			)
		}
	}

	func saveMessage(_ request: Request, context: AuthContext) async throws -> [String: String] {
		guard let userId = context.parameters.get("userId") else { throw HTTPError(.badRequest) }

		let body = try await request.decode(as: SendMessageRequest.self, context: context)
		let me = context.user

		try await database.write { db in
			let conversation = try Friendship
				.where { $0.involves(me.id) && $0.involves(userId) && $0.state.eq(Friendship.State.accepted) }
				.join(Conversation.all) { $1.friendshipId.eq($0.id) }
				.select { $1 }
				.fetchOne(db)
			guard let conversation else { throw HTTPError(.notFound) }

			try Message.upsert {
				Message(
					id: Message.ID(conversationId: conversation.id, senderId: me.id),
					text: body.message.isEmpty ? nil : body.message,
					isOriginal: true, // TODO: figure out where this comes from
					reaction: nil,
					reactionAt: nil,
					updatedAt: body.date
				)
			}
			.execute(db)
		}

		return [:]
	}

	func updateChat(_ request: Request, context: AuthContext) async throws -> [String: String] {
		guard let chatId = context.parameters.get("chatId") else { throw HTTPError(.badRequest) }
		let patch = try await request.decode(as: ChatUpdateRequest.self, context: context)
		let me = context.user

		try await database.write { db in
			try Conversation.where { conversation in
				conversation.id.eq(chatId) && Friendship.where { $0.id.eq(conversation.friendshipId) && $0.involves(me.id) }.exists()
			}
			.update(apply: patch)
			.execute(db)

			try ConversationMember.where { $0.id.conversationId.eq(chatId) && $0.id.userId.eq(me.id) }
				.update(apply: patch)
				.execute(db)
		}

		// TODO: is this the right return type?
		return [:]
	}

	func getFriendship(_: Request, context: AuthContext) throws -> ChatFriendshipResponse {
		guard let userId = context.parameters.get("userId") else { throw HTTPError(.badRequest) }
		let me = context.user

		guard let row = try database.read({ db in
			try Friendship
				.where { $0.involves(me.id) && $0.involves(userId) }
				.join(Conversation.all) { $1.friendshipId.eq($0.id) }
				.join(ConversationMember.all) { $2.id.conversationId.eq($1.id) && $2.id.userId.eq(me.id) }
				.join(User.all) { $3.id.eq($0.friendId(besides: me.id)) }
				.select { ($0, $1, $2, $3, $3.asFriendContext(viewedBy: me)) }
				.fetchOne(db)
		}) else { throw HTTPError(.notFound) }

		let (friendship, conversation, member, user, userContext) = row
		let friend = APIFriendInfo(from: user, with: userContext)

		return ChatFriendshipResponse(
			friendship: APIFriendshipInfo(from: friendship, with: .init(conversation: conversation, state: .init(from: friendship))),
			chat: APIChatInfo(from: conversation, with: .init(friend: friend, member: member)),
			friend: friend
		)
	}

	func updateMagicWords(_ request: Request, context: AuthContext) async throws -> [String: String] {
		guard let chatId = context.parameters.get("chatId") else { throw HTTPError(.badRequest) }
		let body = try await request.decode(as: UpdateMagicWordsRequest.self, context: context)
		let me = context.user

		try await database.write { db in
			try Conversation.where { conversation in
				conversation.id.eq(chatId) && Friendship.where { $0.id.eq(conversation.friendshipId) && $0.involves(me.id) }.exists()
			}
			.update { $0.magicWords = #bind(body.magicWords) }
			.execute(db)
		}

		// TODO: is this the right return type?
		return [:]
	}
}

// MARK: Query Helpers

@Selection
fileprivate struct ChatRows {
	let friendId: String
	@Column(as: [Message].JSONRepresentation.self)
	let messages: [Message]
}
