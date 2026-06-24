import SQLiteData

struct CreateGamesTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "games") { table in
			table.column("id", .text).primaryKey()
			table.column("friendshipId", .text).notNull().references("friendships", column: "id")
			table.column("conversationId", .text).notNull().references("conversations", column: "id")
			table.column("gameType", .text).notNull()
			table.column("status", .text).notNull().defaults(to: "initiated")
			table.column("fromUserId", .text).notNull().references("users", column: "id")
			table.column("state", .jsonb)
			table.column("scores", .jsonb)
			table.column("createdAt", .datetime).notNull().defaults(sql: "(now())")
			table.column("updatedAt", .datetime).notNull().defaults(sql: "(now())")
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "games")
	}
}
