import SQLiteData

struct CreateBlocksTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "blocks") { table in
			table.column("id", .integer).primaryKey()
			table.column("blockerId", .text).notNull().references("users", column: "id")
			table.column("blockedId", .text).notNull().references("users", column: "id")
			table.column("source", .text)
			table.column("createdAt", .datetime).notNull().defaults(sql: "(now())")

			table.uniqueKey(["blockerId", "blockedId"])
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "blocks")
	}
}
