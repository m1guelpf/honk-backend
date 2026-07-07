import SQLiteData

struct CreateComplimentsTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "compliments") { table in
			table.column("id", .text).notNull().primaryKey()
			table.column("fromUserId", .text).notNull().references("users", column: "id")
			table.column("toUserId", .text).notNull().references("users", column: "id")
			table.column("complimentId", .text).notNull()
			table.column("createdAt", .datetime).notNull().defaults(sql: "(now())")
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "compliments")
	}
}
