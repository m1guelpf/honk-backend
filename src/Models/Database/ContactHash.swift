import Foundation
import SQLiteData

@Table
struct ContactHash: Identifiable, Sendable {
	@Selection struct ID: Equatable, Hashable, Sendable {
		var userFirebaseUid: String
		var hash: String
	}

	var id: ID

	init(userFirebaseUid: User.ID, hash: String) {
		id = ID(userFirebaseUid: userFirebaseUid, hash: hash)
	}
}
