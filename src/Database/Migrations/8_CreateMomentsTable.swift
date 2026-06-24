import SQLiteData

struct CreateMomentsTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "moments") { table in
			table.column("id", .text).primaryKey()
			table.column("friendshipId", .text).notNull().references("friendships", column: "id")
			table.column("assetId", .text).notNull().references("assets", column: "id")
			table.column("createdById", .text).notNull().references("users", column: "id")
			table.column("includesCaption", .boolean).notNull().defaults(to: false)
			table.column("metadata", .jsonb)
			table.column("createdAt", .datetime).notNull().defaults(sql: "(now())")
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "moments")
	}
}
