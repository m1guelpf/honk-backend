import SQLiteData

struct CreateConversationsTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "conversations") { table in
			table.column("id", .text).notNull().primaryKey()
			table.column("friendshipId", .text).notNull().references("friendships", column: "id")
			table.column("themeId", .text)
			table.column("isTemporary", .boolean).notNull().defaults(to: false)
			table.column("lastActivityAt", .datetime)
			table.column("lastReceivedAt", .datetime)
			table.column("stats", .text).notNull().defaults(to: "{}")
			table.column("magicWords", .text).notNull().defaults(to: "[]")
			table.column("createdAt", .datetime).notNull()
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "conversations")
	}
}
