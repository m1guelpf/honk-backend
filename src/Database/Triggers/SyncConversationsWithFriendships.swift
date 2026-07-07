import Foundation
import SQLiteData

struct SyncConversationsWithFriendships: Trigger {
	static func install(in database: Database) throws {
		try Friendship.createTemporaryTrigger(after: .insert { friendship in
			Conversation.insert { Conversation.Columns(
				id: $objectID(),
				friendshipId: friendship.id,
				isTemporary: friendship.isTemporary,
				stats: #bind(User.Stats()),
				magicWords: #bind([]),
				createdAt: $now()
			) }
		})
		.execute(database)
	}
}
