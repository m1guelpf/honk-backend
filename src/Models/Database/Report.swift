import Foundation
import SQLiteData

@Table
struct Report: Identifiable {
	@Selection struct ID: Equatable, Hashable {
		var reporterId: User.ID
		var reportedId: User.ID
	}

	var id: ID
	var reason: String
	var source: String?
	var createdAt: Date
}
