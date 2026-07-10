import Foundation
import SQLiteData

@Table
struct Asset: Identifiable {
	enum Kind: String, Equatable, Hashable, Codable, QueryBindable, Sendable {
		case image, audio, video, imagePreview
	}

	var id: String
	var ownerId: User.ID
	var conversationId: Conversation.ID
	var kind: Kind
	var storageRef: String
	var blurHash: String?
	var parameters: String?
	var thumbnails: String?
	var includesCaption: Bool
	var metadata: String?
	var createdAt: Date
}
