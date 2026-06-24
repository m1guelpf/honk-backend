import SQLiteData

struct CreateConversationMembersTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "conversationMembers") { table in
			table.column("conversationId", .text).notNull().references("conversations", column: "id")
			table.column("userId", .text).notNull().references("users", column: "id")
			table.column("nickname", .text)
			table.column("notificationsEnabled", .boolean).notNull().defaults(to: true)
			table.column("mutedUntil", .datetime)
			table.column("pinnedAt", .datetime)
			table.column("hasUnread", .boolean).notNull().defaults(to: false)
			table.column("lastReadAt", .datetime)

			table.primaryKey(["conversationId", "userId"])
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "conversationMembers")
	}
}
