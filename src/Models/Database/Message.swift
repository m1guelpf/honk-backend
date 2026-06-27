import SQLiteData
import Foundation

@Table
struct Message: Identifiable {
	@Selection struct ID: Equatable, Hashable {
		var conversationId: Conversation.ID
		var senderId: User.ID
	}

	var id: ID
	var text: String?
	var isOriginal: Bool
	var reaction: String?
	var reactionAt: Date?
	var updatedAt: Date
}
