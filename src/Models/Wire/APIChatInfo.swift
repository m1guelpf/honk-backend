import Foundation
import Hummingbird

struct APIChatInfo: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var id: String
	var chatNotifications: Bool?
	var unreadNotifications: Bool
	var theme: String
	var friendAudioState: String?
	var friendLastPlayedAudio: APITimestamp?
	var friendLastCompletedAudio: APITimestamp?
	var friendLastPausedAudio: APITimestamp?
	var friendLastRecordedAudio: APITimestamp?
	var magicWords: [User.MagicWord]?
	var muteValue: String?
	var muteUntil: Date?
	var stats: APIConversationStats
	var userId: User.ID?
	var friendLastActiveAt: Date?
	var lastReceivedAt: Date?
	var pinnedAt: Date?
	var nickname: String?
	var reactions: [String]?
	var quickReaction: String?
	var honkButton: User.HonkButtonCategory?
	var friendHonkButton: User.HonkButtonCategory?
}

extension APIChatInfo {
	struct Context {
		var member: ConversationMember?
		var friend: APIFriendInfo
		var fallbackId: String
	}

	init(from conversation: Conversation?, with context: Context) {
		id = conversation?.id ?? context.fallbackId
		chatNotifications = context.member?.notificationsEnabled
		unreadNotifications = context.member?.hasUnread ?? false
		theme = conversation?.themeId ?? "default"
		friendAudioState = nil
		friendLastPlayedAudio = nil
		friendLastCompletedAudio = nil
		friendLastPausedAudio = nil
		friendLastRecordedAudio = nil
		magicWords = conversation?.magicWords
		muteValue = nil
		muteUntil = context.member?.mutedUntil
		stats = conversation.map { APIConversationStats(from: $0.stats) } ?? APIConversationStats()
		userId = context.member?.id.userId
		friendLastActiveAt = nil
		lastReceivedAt = conversation?.lastReceivedAt
		pinnedAt = context.member?.pinnedAt
		nickname = context.member?.nickname
		reactions = nil
		quickReaction = nil
		honkButton = nil
		friendHonkButton = context.friend.honkButton
	}
}
