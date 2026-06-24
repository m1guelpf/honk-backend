import SQLiteData

struct CreateAssetsTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "assets") { table in
			table.column("id", .text).primaryKey()
			table.column("ownerId", .text).notNull().references("users", column: "id")
			table.column("conversationId", .text).notNull().references("conversations", column: "id")
			table.column("kind", .text).notNull()
			table.column("storageRef", .text).notNull()
			table.column("blurHash", .text)
			table.column("parameters", .jsonb)
			table.column("thumbnails", .jsonb)
			table.column("isMoment", .boolean).notNull().defaults(to: false)
			table.column("includesCaption", .boolean).notNull().defaults(to: false)
			table.column("metadata", .jsonb)
			table.column("createdAt", .datetime).notNull().defaults(sql: "(now())")
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "assets")
	}
}
