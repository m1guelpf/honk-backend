import SQLiteData

struct CascadeUserDeleteOnContactHashes: Trigger {
	static func install(in database: Database) throws {
		try User.createTemporaryTrigger(after: .delete { user in
			ContactHash.where { $0.id.userFirebaseUid.eq(user.id) }.delete()
		})
		.execute(database)
	}
}
