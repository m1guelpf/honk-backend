import GRDB
import Logging
import SQLiteData
import Foundation

#if canImport(SQLite3)
import SQLite3
#else
import GRDBSQLite
#endif

@DatabaseFunction(isDeterministic: false)
fileprivate var now: Date {
	@Dependency(\.date.now) var now
	return now
}

fileprivate let logger = Logger(label: "Database")

func makeDatabase() throws -> any DatabaseWriter {
	let database = try defaultDatabase { config in
		config.foreignKeysEnabled = true
		config.prepareDatabase { db in
			db.add(function: $now)
			db.add(function: $objectID)

			var flag: CInt = 0
			let code = withUnsafeMutablePointer(to: &flag) { flagP in
				sqlite3_file_control(db.sqliteConnection, nil, SQLITE_FCNTL_PERSIST_WAL, flagP)
			}
			guard code == SQLITE_OK else {
				throw DatabaseError(resultCode: ResultCode(rawValue: code))
			}

			db.trace(options: .profile) {
				logger.trace("\($0.expandedDescription)")
			}
		}
	}
	logger.info("open '\(database.path)'")

	return database
}

func prepareDatabase(_ database: any DatabaseWriter, readOnly _: Bool = false) throws {
	var migrator = DatabaseMigrator()
	#if DEBUG
	migrator.eraseDatabaseOnSchemaChange = true
	#endif

	try migrator.migrate([
		CreateUsersTable.self,
		CreateFriendshipsTable.self,
		CreateConversationsTable.self,
		CreateConversationMembersTable.self,
		CreateMessagesTable.self,
		CreateAssetsTable.self,
		CreateConversationAssetsTable.self,
		CreateMomentsTable.self,
		CreateComplimentsTable.self,
		CreateBlocksTable.self,
		CreateReportsTable.self,
		CreateGamesTable.self,
		CreateDevicesTable.self,
		CreateContactHashesTable.self,
	], in: database)

	try database.setupTriggers([
		TouchTimestamps.self,
		SyncConversationsWithFriendships.self,
		CascadeUserDeleteOnContactHashes.self,
	])
}

fileprivate func defaultDatabase(_ configure: (inout Configuration) -> Void) throws -> any DatabaseWriter {
	@Dependency(\.context) var context

	var configuration = Configuration()
	configure(&configuration)

	switch context {
		case .live:
			@Dependency(\.config) var config
			return try DatabasePool(
				path: config.requiredString(forKey: "database.path"),
				configuration: configuration
			)
		case .preview, .test:
			return try DatabasePool(
				path: "\(NSTemporaryDirectory())\(UUID().uuidString).db",
				configuration: configuration
			)
	}
}
