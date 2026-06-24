import SQLiteData

struct CreateDevicesTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "devices") { table in
			table.column("id", .integer).primaryKey()
			table.column("userId", .integer).notNull().references("users", column: "id")
			table.column("apnsToken", .text)
			table.column("voipToken", .text)
			table.column("platform", .text).notNull().defaults(to: "ios")
			table.column("appVersion", .text)
			table.column("createdAt", .datetime).notNull().defaults(sql: "(now())")
			table.column("updatedAt", .datetime).notNull().defaults(sql: "(now())")

			table.uniqueKey(["userId", "apnsToken"])
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "devices")
	}
}
