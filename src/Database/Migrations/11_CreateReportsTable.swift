import SQLiteData

struct CreateReportsTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "reports") { table in
			table.column("reporterId", .text).notNull().references("users", column: "id")
			table.column("reportedId", .text).notNull().references("users", column: "id")
			table.column("reason", .text).notNull()
			table.column("source", .text)
			table.column("createdAt", .datetime).notNull().defaults(sql: "(now())")

			table.primaryKey(["reporterId", "reportedId"])
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "reports")
	}
}
