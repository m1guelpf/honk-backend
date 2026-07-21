import Foundation
import SQLiteData

@Table
struct Conversation: Identifiable {
	let id: String
	var friendshipId: Friendship.ID
	var themeId: String?
	var isTemporary: Bool
	var lastActivityAt: Date?
	@Column(as: User.Stats.JSONRepresentation.self)
	var stats: User.Stats
	@Column(as: [User.MagicWord].JSONRepresentation.self)
	var magicWords: [User.MagicWord]
	var createdAt: Date
	var updatedAt: Date
}

// MARK: - Query Helpers

extension Conversation {
	static func between(_ user1: User.ID, and user2: User.ID) -> Where<Conversation> {
		Conversation.where {
			$0.friendshipId.eq(
				Friendship.where {
					$0.involves(user1) && $0.involves(user2) && $0.state.eq(Friendship.State.accepted)
				}
				.select(\.id)
			)
		}
	}
}
