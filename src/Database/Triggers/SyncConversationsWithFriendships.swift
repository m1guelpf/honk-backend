import Foundation
import SQLiteData

struct SyncConversationsWithFriendships: Trigger {
	static var uses: [any ScalarDatabaseFunction] {
		[$createConversation]
	}

	static func install(in database: Database) throws {
		try Friendship.createTemporaryTrigger(after: .insert { friendship in
			Values($createConversation(
				friendshipId: friendship.id,
				firstUserId: friendship.userLowId,
				secondUserId: friendship.userHighId,
				isTemporary: friendship.isTemporary
			))
		})
		.execute(database)
	}
}

@DatabaseFunction
fileprivate func createConversation(friendshipId: Friendship.ID, firstUserId: User.ID, secondUserId: User.ID, isTemporary: Bool) throws {
	@Dependency(\.date.now) var now
	@Dependency(\.defaultDatabase) var database

	try database.unsafeReentrantWrite { db in
		let conversationId = objectID()

		try Conversation.insert {
			Conversation(
				id: conversationId,
				friendshipId: friendshipId,
				isTemporary: isTemporary,
				stats: User.Stats(),
				magicWords: [],
				createdAt: now,
				updatedAt: now
			)
		}
		.execute(db)

		try ConversationMember.insert {
			for userId in [firstUserId, secondUserId] {
				ConversationMember(
					id: .init(
						conversationId: conversationId,
						userId: userId
					),
					notificationsEnabled: true,
					hasUnread: false
				)
			}
		}
		.execute(db)
	}
}
