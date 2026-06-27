import SQLiteData
import Foundation

@Table
struct Game: Identifiable {
	var id: String
	var friendshipId: Friendship.ID
	var conversationId: Conversation.ID
	var gameType: String
	var status: String
	var fromUserId: User.ID
	var state: String?
	var scores: String?
	var createdAt: Date
	var updatedAt: Date
}
