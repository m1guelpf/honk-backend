import SQLiteData

struct CreateConversationAssetsTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "conversationAssets") { table in
			table.column("conversationId", .text).notNull().references("conversations", column: "id", onDelete: .cascade)
			table.column("senderId", .text).notNull().references("users", column: "id", onDelete: .cascade)
			table.column("assetId", .text).notNull().references("assets", column: "id", onDelete: .cascade)
			table.column("recordedAt", .datetime)
			table.column("playedAt", .datetime)
			table.column("completedAt", .datetime)
			table.column("pausedAt", .datetime)
			table.column("updatedAt", .datetime).notNull().defaults(sql: "(now())")

			table.primaryKey(["conversationId", "senderId"])
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "conversationAssets")
	}
}
