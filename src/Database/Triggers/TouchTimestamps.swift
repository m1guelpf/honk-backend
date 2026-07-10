import SQLiteData
import Foundation

struct TouchTimestamps: Trigger {
	static func install(in database: Database) throws {
		// Keep `User.updatedAt` in sync
		try User.createTemporaryTrigger(after: .update { _, user in
			User.find(user.id).update { $0.updatedAt = $now() }
		} when: { old, new in
			old.updatedAt.eq(new.updatedAt)
		})
		.execute(database)

		// Keep `Friendship.updatedAt` in sync
		try Friendship.createTemporaryTrigger(after: .update { _, friendship in
			Friendship.find(friendship.id).update { $0.updatedAt = $now() }
		} when: { old, new in
			old.updatedAt.eq(new.updatedAt)
		})
		.execute(database)

		// Keep `Conversation.updatedAt` in sync
		try Conversation.createTemporaryTrigger(after: .update { _, conversation in
			Conversation.find(conversation.id).update { $0.updatedAt = $now() }
		} when: { old, new in
			old.updatedAt.eq(new.updatedAt)
		})
		.execute(database)
		try ConversationMember.createTemporaryTrigger(after: .update { _, conversationMember in
			Conversation.find(conversationMember.id.conversationId).update { $0.updatedAt = $now() }
		})
		.execute(database)

		// Keep `Conversation.lastActivityAt` in Sync
		try Message.createTemporaryTrigger(after: .update(forEachRow: { _, message in
			Conversation.find(message.id.conversationId).update(set: {
				$0.lastActivityAt = message.updatedAt.asOptional
			})
		}))
		.execute(database)
		try Message.createTemporaryTrigger(after: .insert(forEachRow: { message in
			Conversation.find(message.id.conversationId).update {
				$0.lastActivityAt = message.updatedAt.asOptional
			}
		}))
		.execute(database)
	}
}
