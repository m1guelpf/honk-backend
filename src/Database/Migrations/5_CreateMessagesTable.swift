import SQLiteData

struct CreateMessagesTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "messages") { table in
			table.column("conversationId", .text).notNull().references("conversations", column: "id")
			table.column("senderId", .text).notNull().references("users", column: "id")
			table.column("text", .text)
			table.column("isOriginal", .boolean).notNull().defaults(to: true)
			table.column("reaction", .text)
			table.column("reactionAt", .datetime)
			table.column("updatedAt", .datetime).notNull().defaults(sql: "(now())")

			table.primaryKey(["conversationId", "senderId"])
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "messages")
	}
}
