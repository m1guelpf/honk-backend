import SQLiteData

struct CreateConversationMembersTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "conversationMembers") { table in
			table.column("conversationId", .text).notNull().references("conversations", column: "id", onDelete: .cascade)
			table.column("userId", .text).notNull().references("users", column: "id", onDelete: .cascade)
			table.column("nickname", .text)
			table.column("notificationsEnabled", .boolean).notNull().defaults(to: true)
			table.column("mutedUntil", .datetime)
			table.column("muteValue", .text)
			table.column("pinnedAt", .datetime)
			table.column("hasUnread", .boolean).notNull().defaults(to: false)
			table.column("lastReadAt", .datetime)
			table.column("reactionEmojis", .text)
			table.column("quickReaction", .text)
			table.column("honkButton", .text)

			table.primaryKey(["conversationId", "userId"])
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "conversationMembers")
	}
}
