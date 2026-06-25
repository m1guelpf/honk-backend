import Foundation
import SQLiteData

@Table
struct Block {
	@Selection
	struct ID {
		var blockerId: User.ID
		var blockedId: User.ID
	}

	var id: ID
	var source: String
	var createdAt: Date
}
