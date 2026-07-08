import Foundation
import SQLiteData

@Table
struct Asset: Identifiable {
	var id: String
	var ownerId: User.ID
	var conversationId: Conversation.ID
	var kind: String
	var storageRef: String
	var blurHash: String?
	var parameters: String?
	var thumbnails: String?
	var includesCaption: Bool
	var metadata: String?
	var createdAt: Date
}
