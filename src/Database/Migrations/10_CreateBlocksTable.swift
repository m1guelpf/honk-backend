import SQLiteData

struct CreateBlocksTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "blocks") { table in
			table.column("blockerId", .text).notNull().references("users", column: "id", onDelete: .cascade)
			table.column("blockedId", .text).notNull().indexed().references("users", column: "id", onDelete: .cascade)
			table.column("source", .text)
			table.column("createdAt", .datetime).notNull().defaults(sql: "(now())")

			table.primaryKey(["blockerId", "blockedId"])
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "blocks")
	}
}
