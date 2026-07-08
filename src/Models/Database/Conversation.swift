import SQLiteData
import Foundation

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
