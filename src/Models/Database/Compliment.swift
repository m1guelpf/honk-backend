import Foundation
import SQLiteData

@Table
struct Compliment: Identifiable, Equatable, Hashable, Sendable {
	let id: String
	var fromUserId: User.ID
	var toUserId: User.ID
	var complimentId: String
	var createdAt: Date
}
