import GRDB
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

extension Compliment {
	/// How many times each user has received each compliment, keyed by recipient and then compliment id.
	static func counts(for userIds: [User.ID], in db: Database) throws -> [User.ID: [String: Int]] {
		let rows = try Compliment
			.where { $0.toUserId.in(userIds) }
			.group { ($0.toUserId, $0.complimentId) }
			.select { ($0.toUserId, $0.complimentId, $0.count()) }
			.fetchAll(db)

		// TODO: Can we do this inside the query
		var counts: [User.ID: [String: Int]] = [:]
		for (userId, complimentId, count) in rows {
			counts[userId, default: [:]][complimentId] = count
		}

		return counts
	}
}
