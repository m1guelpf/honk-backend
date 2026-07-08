import Foundation
import SQLiteData
import Hummingbird

struct ChatUpdateRequest: Equatable, Hashable, Sendable {
	var nickname: String??
	var themeID: String?

	var isNotificationsEnabled: Bool?
	var pinnedAt: Date??
	var muteUntil: Date??
	var muteValue: ConversationMember.MutedFor??

	var reactions: [String]?
	var quickReaction: String??
	var honkButton: User.HonkButtonCategory?
}

extension ChatUpdateRequest: Decodable {
	private enum CodingKeys: String, CodingKey {
		case nickname, themeID, isNotificationsEnabled, pinnedAt, muteUntil, muteValue, reactions, quickReaction, honkButton
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		nickname = try container.decodePatchOptional(String.self, forKey: .nickname)
		themeID = try container.decodeIfPresent(String.self, forKey: .themeID)
		isNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .isNotificationsEnabled)
		pinnedAt = try container.decodePatchOptional(Date.self, forKey: .pinnedAt)
		muteUntil = try container.decodePatchOptional(Date.self, forKey: .muteUntil)
		muteValue = try container.decodePatchOptional(ConversationMember.MutedFor.self, forKey: .muteValue)
		reactions = try container.decodeIfPresent([String].self, forKey: .reactions)
		quickReaction = try container.decodePatchOptional(String.self, forKey: .quickReaction)
		honkButton = try container.decodeIfPresent(User.HonkButtonCategory.self, forKey: .honkButton)
	}
}

extension Where<Conversation> {
	func update(apply patch: ChatUpdateRequest) -> UpdateOf<Conversation> {
		update {
			if let themeID = patch.themeID { $0.themeId = #bind(themeID) }
		}
	}
}

extension Where<ConversationMember> {
	func update(apply patch: ChatUpdateRequest) -> UpdateOf<ConversationMember> {
		update {
			if let nickname = patch.nickname { $0.nickname = nickname }
			if let pinnedAt = patch.pinnedAt { $0.pinnedAt = pinnedAt }
			if let muteUntil = patch.muteUntil { $0.mutedUntil = muteUntil }
			if let muteValue = patch.muteValue { $0.muteValue = muteValue }
			if let honkButton = patch.honkButton { $0.honkButton = #bind(honkButton) }
			if let reactions = patch.reactions { $0.reactionEmojis = #bind(reactions) }
			if let quickReaction = patch.quickReaction { $0.quickReaction = quickReaction }
			if let isNotificationsEnabled = patch.isNotificationsEnabled { $0.notificationsEnabled = isNotificationsEnabled }
		}
	}
}
