import Foundation
import Hummingbird

struct RawUserAccountInfo: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	enum EmojiSkinTone: String, CaseIterable, Equatable, Hashable, Codable, ResponseCodable, Sendable {
		case `default`, light, mediumLight, medium, mediumDark, dark
	}

	enum RawBioColor: String, CaseIterable, Equatable, Hashable, Codable, ResponseCodable, Sendable {
		case blue, yellow, green, pink, peach, grey
	}

	enum StatusTimeoutLength: String, CaseIterable, Equatable, Hashable, Codable, ResponseCodable, Sendable {
		case halfHour, oneHour, threeHours, twentyFourHours, never
	}

	struct UserAccountStats: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		var totalCharactersSent: Int
		var totalHonksSent: Int
		var totalImagesSent: Int
	}

	struct MagicWord: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		var trigger: String
		var reaction: String
		var identifier: String?
	}

	enum Gender: String, CaseIterable, Equatable, Hashable, Codable, ResponseCodable, Sendable {
		case man, woman, genderqueer
	}

	struct Location: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		var city: String
		var subCountry: String
		var country: String
	}

	struct HonkButtonCategory: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		// ??
	}

	var _id: String
	var firebaseAuthId: String
	var name: String
	var username: String
	var avatarURL: URL
	var avatarBlurHash: String?
	var createdAt: Date
	var birthday: Date
	var isNotificationsEnabled: Bool
	var isVerified: Bool
	var allowFriendRequests: Bool
	var showInSuggested: Bool
	var preferredEmojiSkinTone: EmojiSkinTone
	var reactionEmojis: [String]
	var quickReaction: String
	var bio: String
	var bioColor: RawBioColor
	var status: String
	var statusEmoji: String
	var statusTimeout: Date?
	var statusClearValue: StatusTimeoutLength
	var stats: UserAccountStats
	var supportCode: String?
	var invited: Int
	var globalMagicWords: [MagicWord]
	var contactHash: String?
	var meetNotifyEnabled: Bool?
	var meetInterests: [String]?
	var meetGender: [Gender]?
	var meetNotificationsEnabled: Bool?
	var pronouns: [String]?
	var gender: Gender?
	var meetLocation: Location
	var starSign: String?
	var matchRating: Float?
	var allowMatchAudio: Bool
	var allowMatchImages: Bool
	var allowMatchVideos: Bool
	var discoverDisabled: Bool
	var hasAgreedToMeetTerms: Bool
	var hasReducedHonks: Bool
	var teamNotificationsEnabled: Bool
	var streakNotificationsDisabled: Bool
	var hasReducedNotifications: Bool
	var topPicksNotificationEnabled: Bool
	var feelingLuckyNotificationEnabled: Bool
	var badgeCount: Int
	var compliments: [String: Int] // complimentId → count
	var needsConfirmDOB: Bool
	var shouldForceReloadFriends: Bool
	var honkButton: HonkButtonCategory
}
