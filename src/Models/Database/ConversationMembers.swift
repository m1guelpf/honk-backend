import Foundation
import SQLiteData

@Table
struct ConversationMember: Identifiable {
	@Selection struct ID: Equatable, Hashable {
		var conversationId: Conversation.ID
		var userId: User.ID
	}

	enum MutedFor: String, Equatable, Hashable, QueryBindable, Codable, Sendable {
		case oneHour, threeHours, twentyFourHours, untilTurnedOff
	}

	var id: ID
	var nickname: String?
	var notificationsEnabled: Bool
	var mutedUntil: Date?
	var muteValue: MutedFor?
	var pinnedAt: Date?
	var hasUnread: Bool
	var lastReadAt: Date?
	@Column(as: [String]?.JSONRepresentation.self)
	var reactionEmojis: [String]?
	var quickReaction: String?
	var honkButton: User.HonkButtonCategory?
}
