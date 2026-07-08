import Foundation
import SQLiteData

@Table
struct Device: Identifiable {
	@Selection struct ID: Equatable, Hashable {
		var deviceId: String
		var userId: User.ID
	}

	var id: ID
	var apnsToken: String?
	var voipToken: String?
	var platform: String
	var appVersion: String?
	var sandbox: Bool
	var createdAt: Date
	var updatedAt: Date
}
