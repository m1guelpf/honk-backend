import SQLiteData

struct CreateDevicesTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "devices") { table in
			table.column("deviceId", .text).notNull()
			table.column("userId", .text).notNull().references("users", column: "id", onDelete: .cascade)
			table.column("apnsToken", .text)
			table.column("voipToken", .text)
			table.column("platform", .text).notNull().defaults(to: "ios")
			table.column("appVersion", .text)
			table.column("sandbox", .boolean).notNull().defaults(to: false)
			table.column("createdAt", .datetime).notNull().defaults(sql: "(now())")
			table.column("updatedAt", .datetime).notNull().defaults(sql: "(now())")

			table.primaryKey(["deviceId", "userId"])
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "devices")
	}
}
