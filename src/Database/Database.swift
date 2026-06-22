import GRDB
import SQLite3
import Logging
import SQLiteData
import Foundation

fileprivate nonisolated let logger = Logger(label: "Database")

func makeDatabase() throws -> any DatabaseWriter {
	let database = try defaultDatabase { config in
		config.foreignKeysEnabled = true
		config.prepareDatabase { db in
			var flag: CInt = 0
			let code = withUnsafeMutablePointer(to: &flag) { flagP in
				sqlite3_file_control(db.sqliteConnection, nil, SQLITE_FCNTL_PERSIST_WAL, flagP)
			}
			guard code == SQLITE_OK else {
				throw DatabaseError(resultCode: ResultCode(rawValue: code))
			}

			#if DEBUG
			db.trace(options: .profile) {
				logger.debug("\($0.expandedDescription)")
			}
			#endif
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
		//
	], in: database)

	try database.setupTriggers([
		//
	])
}

fileprivate func defaultDatabase(_ configure: (inout Configuration) -> Void) throws -> any DatabaseWriter {
	@Dependency(\.context) var context

	var configuration = Configuration()
	configure(&configuration)

	return try SQLiteData.defaultDatabase(configuration: configuration)
}
