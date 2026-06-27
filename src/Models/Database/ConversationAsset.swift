import SQLiteData
import Foundation

@Table
struct ConversationAsset {
	@Selection struct ID: Equatable, Hashable {
		var conversationId: Conversation.ID
		var senderId: User.ID
	}

	var id: ID
	var assetId: Asset.ID
	var recordedAt: Date?
	var playedAt: Date?
	var completedAt: Date?
	var pausedAt: Date?
	var updatedAt: Date
}
