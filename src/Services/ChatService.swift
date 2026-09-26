import Foundation
import SQLiteData
import Hummingbird
import Dependencies

struct ChatService: Sendable {
	@Dependency(\.date.now) private var now
	@Dependency(\.gateway) private var gateway
	@Dependency(\.defaultDatabase) private var database

	func saveMessage(_ text: String, from sender: User.ID, to recipient: User.ID, at date: Date) async throws {
		try await gateway.run { gateway in
			let activeChat = gateway.activeChat(userID: recipient)
			let updatedChat = try database.write { db -> Conversation.ID? in
				guard let conversation = try Conversation.between(sender, and: recipient).fetchOne(db) else { throw HTTPError(.notFound) }

				try Message.upsert {
					Message(id: Message.ID(conversationId: conversation.id, senderId: sender), text: text.isEmpty ? nil : text, isOriginal: true, updatedAt: date)
				}
				.execute(db)

				guard !text.isEmpty else { return nil }
				return try markUnread(conversation, for: recipient, activeChat: activeChat, in: db)
			}

			if let updatedChat {
				try sendUpdate(for: updatedChat, to: recipient, gateway: gateway)
			}
		}
	}

	func saveAsset(_ event: ClientEvent.ChatAsset, from sender: User.ID) async throws {
		guard event.shouldPersist == true, let kind = Asset.Kind(rawValue: event.data.assetType) else { return }
		let contentID = event.data.contentID.uuidString

		try await gateway.run { gateway in
			let activeChat = gateway.activeChat(userID: event.to)
			let updatedChat = try database.write { db -> Conversation.ID? in
				guard let conversation = try Conversation.between(sender, and: event.to).fetchOne(db) else { throw HTTPError(.notFound) }

				try Asset.upsert {
					Asset(
						id: contentID,
						ownerId: sender,
						kind: kind,
						storageRef: "assets/\(contentID)",
						blurHash: event.data.blurHash,
						parameters: event.data,
						thumbnails: nil,
						includesCaption: !event.data.caption.isEmpty,
						metadata: nil,
						createdAt: now
					)
				}
				.execute(db)

				try ConversationAsset.upsert {
					ConversationAsset(
						id: ConversationAsset.ID(conversationId: conversation.id, senderId: sender),
						assetId: contentID,
						recordedAt: nil,
						playedAt: nil,
						completedAt: nil,
						pausedAt: nil,
						updatedAt: now
					)
				}
				.execute(db)

				return try markUnread(conversation, for: event.to, activeChat: activeChat, in: db)
			}

			if let updatedChat { try sendUpdate(for: updatedChat, to: event.to, gateway: gateway) }
		}
	}

	func sendUpdate(for conversationID: Conversation.ID, to userID: User.ID, friendAudioState: String? = nil, gateway: isolated Gateway) throws {
		guard gateway.isOnline(userID: userID) else { return }
		guard let row = try database.read({ db in
			try Conversation.find(conversationID)
				.join(ConversationMember.all) { $1.id.conversationId.eq($0.id) && $1.id.userId.eq(userID) }
				.join(Friendship.all) { $2.id.eq($0.friendshipId) }
				.join(User.all) { $3.id.eq($2.friendId(besides: userID)) }
				.select { ($0, $1, $3, $3.asFriendContext(viewedBy: userID)) }
				.fetchOne(db)
		}) else { return }

		let (conversation, member, user, context) = row
		let friend = APIFriendInfo(from: user, with: context, isOnline: gateway.isOnline(userID: user.id))
		gateway.send(.chatUpdate(.init(
			key: conversation.id,
			data: APIChatInfo(from: conversation, with: .init(friend: friend, member: member, friendAudioState: friendAudioState))
		)), to: userID)
	}

	private func markUnread(_ conversation: Conversation, for userID: User.ID, activeChat: Friendship.ID?, in db: Database) throws -> Conversation.ID? {
		guard activeChat != conversation.friendshipId else { return nil }

		let query = ConversationMember
			.where { $0.id.conversationId.eq(conversation.id) && $0.id.userId.eq(userID) && !$0.hasUnread }
			.update { $0.hasUnread = true }
			.returning(\.id.conversationId)
		return try query.fetchOne(db)
	}
}

// MARK: - Dependency

extension ChatService: DependencyKey {
	static let liveValue = ChatService()
	static var testValue: ChatService { ChatService() }
}

extension DependencyValues {
	var chatService: ChatService {
		get { self[ChatService.self] }
		set { self[ChatService.self] = newValue }
	}
}
