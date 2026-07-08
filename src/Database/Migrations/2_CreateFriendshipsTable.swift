import SQLiteData

struct CreateFriendshipsTable: Migration {
	static func up(_ db: Database) throws {
		try db.create(table: "friendships") { table in
			table.column("id", .text).notNull().primaryKey()
			table.column("userLowId", .text).notNull().references("users", column: "id", onDelete: .cascade)
			table.column("userHighId", .text).notNull().indexed().references("users", column: "id", onDelete: .cascade)
			table.column("state", .text).notNull().defaults(to: "pending")
			table.column("creator", .text).notNull().references("users", column: "id", onDelete: .cascade)
			table.column("requestMessage", .text)
			table.column("isTemporary", .boolean).notNull().defaults(to: false)
			table.column("isDiscover", .boolean).notNull().defaults(to: false)
			table.column("isFromTopPick", .boolean).notNull().defaults(to: false)
			table.column("interestId", .text)
			table.column("currentStreakCount", .integer).notNull().defaults(to: 0)
			table.column("bestStreakCount", .integer).notNull().defaults(to: 0)
			table.column("lastStreakDate", .datetime)
			table.column("score", .integer)
			table.column("likelyOffensive", .boolean).notNull().defaults(to: false)
			table.column("createdAt", .datetime).notNull().defaults(sql: "(now())")
			table.column("updatedAt", .datetime).notNull().defaults(sql: "(now())")

			table.uniqueKey(["userLowId", "userHighId"])
		}
	}

	static func down(_ db: Database) throws {
		try db.drop(table: "friendships")
	}
}
