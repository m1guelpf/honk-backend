import SQLiteData

struct CreateGamesTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "games") { table in
			table.column("id", .text).notNull().primaryKey()
			table.column("friendshipId", .text).notNull().references("friendships", column: "id", onDelete: .cascade)
			table.column("gameType", .text).notNull()
			table.column("status", .text).notNull().defaults(to: "initiated")
			table.column("fromUserId", .text).notNull().references("users", column: "id", onDelete: .cascade)
			table.column("state", .text)
			table.column("scores", .text)
			table.column("createdAt", .datetime).notNull().defaults(sql: "(now())")
			table.column("updatedAt", .datetime).notNull().defaults(sql: "(now())")
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "games")
	}
}
