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
	var muteValue: ConversationMember.MutedFor?
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
		var friend: APIFriendInfo
		var member: ConversationMember
	}

	init(from conversation: Conversation, with context: Context) {
		id = conversation.id
		chatNotifications = context.member.notificationsEnabled
		unreadNotifications = context.member.hasUnread
		theme = conversation.themeId ?? "standard"
		friendAudioState = nil
		friendLastPlayedAudio = nil
		friendLastCompletedAudio = nil
		friendLastPausedAudio = nil
		friendLastRecordedAudio = nil
		magicWords = conversation.magicWords
		muteValue = context.member.mutedValue
		muteUntil = context.member.mutedUntil
		stats = APIConversationStats(from: conversation.stats)
		userId = context.member.id.userId
		friendLastActiveAt = nil
		lastReceivedAt = conversation.lastActivityAt
		pinnedAt = context.member.pinnedAt
		nickname = context.member.nickname
		reactions = context.member.reactionEmojis
		quickReaction = context.member.quickReaction
		honkButton = context.member.honkButton
		friendHonkButton = context.friend.honkButton
	}
}
