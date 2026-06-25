import Foundation
import SQLiteData

@Table
struct Device {
	@Selection
	struct ID {
		var deviceId: String
		var userId: User.ID
	}

	var id: ID
	var apnsToken: String?
	var voipToken: String?
	var platform: String
	var appVersion: String
	var sandbox: Bool
	var createdAt: Date
	var updatedAt: Date
}
