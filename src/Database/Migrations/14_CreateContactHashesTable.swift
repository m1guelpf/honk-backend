import SQLiteData

struct CreateContactHashesTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "contactHashes") { table in
			table.column("userFirebaseUid", .text).notNull()
			table.column("hash", .text).notNull().indexed()

			table.primaryKey(["userFirebaseUid", "hash"])
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "contactHashes")
	}
}
