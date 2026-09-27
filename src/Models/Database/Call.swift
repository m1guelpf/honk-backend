import Foundation
import SQLiteData

@Table
struct Call: Identifiable {
	enum State: String, Codable, QueryBindable, Sendable {
		case requested, accepted, declined
	}

	let id: UUID
	var friendshipId: Friendship.ID
	var callerId: User.ID
	var recipientId: User.ID
	var state: State
	var expiresAt: Date
	var createdAt: Date
	var updatedAt: Date

	var tokenExpiry: Date { createdAt.adding(.days(1)) }

	func otherUser(besides userID: User.ID) -> User.ID {
		callerId == userID ? recipientId : callerId
	}
}

extension Call.TableColumns {
	func involves(_ userID: some QueryExpression<User.ID>) -> some QueryExpression<Bool> {
		callerId.eq(userID) || recipientId.eq(userID)
	}
}
