import Foundation
import SQLiteData
import Hummingbird

@Table
struct User: Identifiable, Equatable, Hashable, Sendable {
	enum EmojiSkinTone: String, CaseIterable, Equatable, Hashable, Codable, ResponseCodable, QueryBindable, Sendable {
		case `default`, light, mediumLight, medium, mediumDark, dark
	}

	enum StatusTimeoutLength: String, CaseIterable, Equatable, Hashable, Codable, ResponseCodable, QueryBindable, Sendable {
		case halfHour, oneHour, threeHours, twentyFourHours, never
	}

	enum BioColor: String, CaseIterable, Equatable, Hashable, Codable, ResponseCodable, QueryBindable, Sendable {
		case blue, yellow, green, pink, peach, grey
	}

	enum Gender: String, CaseIterable, Equatable, Hashable, Codable, ResponseCodable, QueryBindable, Sendable {
		case man, woman, genderqueer
	}

	struct Location: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		var city: String
		var subCountry: String
		var country: String
	}

	struct MagicWord: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		var trigger: String
		var reaction: String
		var identifier: String?
	}

	struct Stats: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		var totalHonksSent: Int
		var totalImagesSent: Int
		var totalCharactersSent: Int

		init(totalHonksSent: Int = 0, totalImagesSent: Int = 0, totalCharactersSent: Int = 0) {
			self.totalHonksSent = totalHonksSent
			self.totalImagesSent = totalImagesSent
			self.totalCharactersSent = totalCharactersSent
		}
	}

	enum HonkButtonCategory: String, CaseIterable, Equatable, Hashable, Codable, ResponseCodable, QueryBindable, Sendable {
		case classic, fruit, animal, music, space, love
	}

	let id: String
	var firebaseUid: String
	var username: String
	var name: String
	var phoneNumber: String?
	var avatarUrl: URL
	var avatarBlurHash: String?
	var bio: String
	var bioColor: BioColor?
	var preferredEmojiSkinTone: EmojiSkinTone
	var status: String
	var statusEmoji: String
	var statusTimeout: Date?
	var statusClearValue: StatusTimeoutLength?
	var birthday: Date
	var gender: Gender?
	var starSign: String?
	var isVerified: Bool
	var allowFriendRequests: Bool
	var showInSuggested: Bool
	var discoverDisabled: Bool
	var hasAgreedMeetTerms: Bool
	var supportCode: String
	var contactHash: String?
	var needsConfirmDOB: Bool
	var invited: Int
	var badgeCount: Int
	var matchRating: Float?
	@Column(as: [String]?.JSONRepresentation.self)
	var pronouns: [String]?
	@Column(as: [String].JSONRepresentation.self)
	var reactionEmojis: [String]
	var quickReaction: String
	@Column(as: [String].JSONRepresentation.self)
	var meetInterests: [String]
	@Column(as: [Gender]?.JSONRepresentation.self)
	var meetGender: [Gender]?
	@Column(as: Location?.JSONRepresentation.self)
	var meetLocation: Location?
	@Column(as: [MagicWord].JSONRepresentation.self)
	var globalMagicWords: [MagicWord]
	@Column(as: Stats.JSONRepresentation.self)
	var stats: Stats
	var allowMatchAudio: Bool
	var allowMatchImages: Bool
	var allowMatchVideos: Bool
	var honkButton: HonkButtonCategory
	var isNotificationsEnabled: Bool
	var meetNotifyEnabled: Bool?
	var meetNotificationsEnabled: Bool?
	var teamNotificationsEnabled: Bool
	var streakNotificationsDisabled: Bool
	var hasReducedHonks: Bool
	var hasReducedNotifications: Bool
	var topPicksNotificationEnabled: Bool
	var feelingLuckyNotificationEnabled: Bool
	var createdAt: Date
	var updatedAt: Date

	init(
		id: String,
		firebaseUid: String,
		username: String,
		name: String,
		phoneNumber: String? = nil,
		avatarUrl: URL,
		avatarBlurHash: String? = nil,
		bio: String = "",
		bioColor: BioColor? = nil,
		preferredEmojiSkinTone: EmojiSkinTone = .default,
		status: String = "",
		statusEmoji: String = "",
		statusTimeout: Date? = nil,
		statusClearValue: StatusTimeoutLength? = nil,
		birthday: Date,
		gender: Gender? = nil,
		starSign: String? = nil,
		isVerified: Bool = false,
		allowFriendRequests: Bool = true,
		showInSuggested: Bool = true,
		discoverDisabled: Bool = false,
		hasAgreedMeetTerms: Bool = false,
		supportCode: String = "",
		contactHash: String? = nil,
		needsConfirmDOB: Bool = false,
		invited: Int = 0,
		badgeCount: Int = 0,
		matchRating: Float? = nil,
		pronouns: [String]? = nil,
		reactionEmojis: [String] = [],
		quickReaction: String = "",
		meetInterests: [String] = [],
		meetGender: [Gender]? = nil,
		meetLocation: Location? = nil,
		globalMagicWords: [MagicWord] = [],
		stats: Stats = Stats(),
		allowMatchAudio: Bool = true,
		allowMatchImages: Bool = true,
		allowMatchVideos: Bool = true,
		honkButton: HonkButtonCategory = .classic,
		isNotificationsEnabled: Bool = true,
		meetNotifyEnabled: Bool? = nil,
		meetNotificationsEnabled: Bool? = nil,
		teamNotificationsEnabled: Bool = true,
		streakNotificationsDisabled: Bool = false,
		hasReducedHonks: Bool = false,
		hasReducedNotifications: Bool = false,
		topPicksNotificationEnabled: Bool = true,
		feelingLuckyNotificationEnabled: Bool = true,
		createdAt: Date,
		updatedAt: Date
	) {
		self.id = id
		self.bio = bio
		self.name = name
		self.stats = stats
		self.gender = gender
		self.status = status
		self.invited = invited
		self.pronouns = pronouns
		self.bioColor = bioColor
		self.birthday = birthday
		self.starSign = starSign
		self.username = username
		self.avatarUrl = avatarUrl
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.isVerified = isVerified
		self.badgeCount = badgeCount
		self.meetGender = meetGender
		self.honkButton = honkButton
		self.supportCode = supportCode
		self.contactHash = contactHash
		self.firebaseUid = firebaseUid
		self.phoneNumber = phoneNumber
		self.statusEmoji = statusEmoji
		self.matchRating = matchRating
		self.meetLocation = meetLocation
		self.statusTimeout = statusTimeout
		self.quickReaction = quickReaction
		self.meetInterests = meetInterests
		self.avatarBlurHash = avatarBlurHash
		self.reactionEmojis = reactionEmojis
		self.needsConfirmDOB = needsConfirmDOB
		self.showInSuggested = showInSuggested
		self.allowMatchAudio = allowMatchAudio
		self.hasReducedHonks = hasReducedHonks
		self.statusClearValue = statusClearValue
		self.discoverDisabled = discoverDisabled
		self.globalMagicWords = globalMagicWords
		self.allowMatchImages = allowMatchImages
		self.allowMatchVideos = allowMatchVideos
		self.meetNotifyEnabled = meetNotifyEnabled
		self.hasAgreedMeetTerms = hasAgreedMeetTerms
		self.allowFriendRequests = allowFriendRequests
		self.preferredEmojiSkinTone = preferredEmojiSkinTone
		self.isNotificationsEnabled = isNotificationsEnabled
		self.hasReducedNotifications = hasReducedNotifications
		self.meetNotificationsEnabled = meetNotificationsEnabled
		self.teamNotificationsEnabled = teamNotificationsEnabled
		self.streakNotificationsDisabled = streakNotificationsDisabled
		self.topPicksNotificationEnabled = topPicksNotificationEnabled
		self.feelingLuckyNotificationEnabled = feelingLuckyNotificationEnabled
	}
}
