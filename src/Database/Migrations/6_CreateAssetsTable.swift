import SQLiteData

struct CreateAssetsTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "assets") { table in
			table.column("id", .text).notNull().primaryKey()
			table.column("ownerId", .text).notNull().references("users", column: "id", onDelete: .cascade)
			table.column("conversationId", .text).notNull().references("conversations", column: "id", onDelete: .cascade)
			table.column("kind", .text).notNull()
			table.column("storageRef", .text).notNull()
			table.column("blurHash", .text)
			table.column("parameters", .text)
			table.column("thumbnails", .text)
			table.column("includesCaption", .boolean).notNull().defaults(to: false)
			table.column("metadata", .text)
			table.column("createdAt", .datetime).notNull().defaults(sql: "(now())")
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "assets")
	}
}
