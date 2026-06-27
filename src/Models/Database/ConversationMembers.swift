import Foundation
import SQLiteData

@Table
struct ConversationMember: Identifiable {
	@Selection struct ID: Equatable, Hashable {
		var conversationId: Conversation.ID
		var userId: User.ID
	}

	var id: ID
	var nickname: String?
	var notificationsEnabled: Bool
	var mutedUntil: Date?
	var pinnedAt: Date?
	var hasUnread: Bool
	var lastReadAt: Date?
}
