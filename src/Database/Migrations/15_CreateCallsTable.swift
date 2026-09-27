import SQLiteData

struct CreateCallsTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "calls") { table in
			table.column("id", .text).notNull().primaryKey()
			table.column("friendshipId", .text).notNull().references("friendships", column: "id", onDelete: .cascade)
			table.column("callerId", .text).notNull().indexed().references("users", column: "id", onDelete: .cascade)
			table.column("recipientId", .text).notNull().indexed().references("users", column: "id", onDelete: .cascade)
			table.column("state", .text).notNull()
			table.column("expiresAt", .datetime).notNull().indexed()
			table.column("createdAt", .datetime).notNull()
			table.column("updatedAt", .datetime).notNull()
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "calls")
	}
}
