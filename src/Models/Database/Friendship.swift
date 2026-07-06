import SQLiteData
import Foundation

@Table
struct Friendship: Identifiable {
	enum State: String, CaseIterable, Equatable, Hashable, Codable, QueryBindable, Sendable {
		case pending, accepted, declined
	}

	let id: String
	var userLowId: User.ID
	var userHighId: User.ID
	var state: State
	var creator: User.ID
	var requestMessage: String?
	var isTemporary: Bool
	var isDiscover: Bool
	var isFromTopPick: Bool
	var interestId: String?
	var currentStreakCount: Int
	var bestStreakCount: Int
	var lastStreakDate: Date?
	var score: Int?
	var likelyOffensive: Bool
	var lastActivityAt: Date?
	var createdAt: Date
	var updatedAt: Date
}

extension Friendship {
	/// The id of the other participant in the friendship, from the perspective of `viewerId`.
	func friendId(besides viewerId: User.ID) -> User.ID {
		userLowId == viewerId ? userHighId : userLowId
	}
}

extension Friendship.TableColumns {
	/// The id of the other participant in the friendship, from the perspective of `viewerId`.
	func friendId(besides viewerId: some QueryExpression<User.ID>) -> some QueryExpression<User.ID> {
		Case().when(userLowId.eq(viewerId), then: userHighId).else(userLowId)
	}

	/// Whether the `userId` column is one of the two participants in the friendship.
	func involves(_ userId: some QueryExpression<User.ID>) -> some QueryExpression<Bool> {
		userLowId.eq(userId) || userHighId.eq(userId)
	}
}
