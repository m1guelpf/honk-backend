import Foundation
import SQLiteData
import Hummingbird

struct AccountUpdateRequest: Equatable, Hashable, Sendable {
	var name: String?
	var username: String?

	var avatarURL: URL?
	var avatarBlurHash: String??

	var birthday: Date?

	var isNotificationsEnabled: Bool?
	var allowFriendRequests: Bool?
	var showInSuggested: Bool?

	var preferredEmojiSkinTone: User.EmojiSkinTone??

	var reactionEmojis: [String]?
	var quickReaction: String?

	var bio: String?
	var bioColor: User.BioColor?

	var status: String?
	var statusEmoji: String?

	var statusTimeout: Date??
	var statusClearValue: User.StatusTimeoutLength??

	var meetNotifyEnabled: Bool??
	var meetInterests: [String]??
	var meetGender: [User.Gender]?
	var meetNotificationsEnabled: Bool??

	var pronouns: [String]?
	var gender: User.Gender??
	var meetLocation: User.Location??

	var starSign: String??
	var matchRating: Float??

	var allowMatchAudio: Bool?
	var allowMatchImages: Bool?
	var allowMatchVideos: Bool?

	var discoverDisabled: Bool?

	var hasAgreedToMeetTerms: Bool?
	var needsConfirmDOB: Bool?
	var shouldForceReloadFriends: Bool?

	var hasReducedHonks: Bool?
	var teamNotificationsEnabled: Bool?
	var streakNotificationsDisabled: Bool?
	var hasReducedNotifications: Bool?
	var topPicksNotificationEnabled: Bool?
	var feelingLuckyNotificationEnabled: Bool?

	var honkButton: User.HonkButtonCategory?
}

extension AccountUpdateRequest: Decodable {
	private enum CodingKeys: String, CodingKey {
		case feelingLuckyNotificationEnabled, honkButton,
		     name, username, avatarURL, avatarBlurHash, birthday,
		     preferredEmojiSkinTone, reactionEmojis, quickReaction, bio,
		     isNotificationsEnabled, allowFriendRequests, showInSuggested,
		     bioColor, status, statusEmoji, statusTimeout, statusClearValue,
		     shouldForceReloadFriends, hasReducedHonks, teamNotificationsEnabled,
		     meetNotifyEnabled, meetInterests, meetGender, meetNotificationsEnabled,
		     allowMatchVideos, discoverDisabled, hasAgreedToMeetTerms, needsConfirmDOB,
		     streakNotificationsDisabled, hasReducedNotifications, topPicksNotificationEnabled,
		     pronouns, gender, meetLocation, starSign, matchRating, allowMatchAudio, allowMatchImages
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		name = try container.decodeIfPresent(String.self, forKey: .name)
		username = try container.decodeIfPresent(String.self, forKey: .username)
		avatarURL = try container.decodeIfPresent(URL.self, forKey: .avatarURL)
		avatarBlurHash = try container.decodePatchOptional(String.self, forKey: .avatarBlurHash)
		birthday = try container.decodeIfPresent(Date.self, forKey: .birthday)
		isNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .isNotificationsEnabled)
		allowFriendRequests = try container.decodeIfPresent(Bool.self, forKey: .allowFriendRequests)
		showInSuggested = try container.decodeIfPresent(Bool.self, forKey: .showInSuggested)
		preferredEmojiSkinTone = try container.decodePatchOptional(User.EmojiSkinTone.self, forKey: .preferredEmojiSkinTone)
		reactionEmojis = try container.decodeIfPresent([String].self, forKey: .reactionEmojis)
		quickReaction = try container.decodeIfPresent(String.self, forKey: .quickReaction)
		bio = try container.decodeIfPresent(String.self, forKey: .bio)
		bioColor = try container.decodeIfPresent(User.BioColor.self, forKey: .bioColor)
		status = try container.decodeIfPresent(String.self, forKey: .status)
		statusEmoji = try container.decodeIfPresent(String.self, forKey: .statusEmoji)
		statusTimeout = try container.decodePatchOptional(Date.self, forKey: .statusTimeout)
		statusClearValue = try container.decodePatchOptional(User.StatusTimeoutLength.self, forKey: .statusClearValue)
		meetNotifyEnabled = try container.decodePatchOptional(Bool.self, forKey: .meetNotifyEnabled)
		meetInterests = try container.decodePatchOptional([String].self, forKey: .meetInterests)
		meetGender = try container.decodeIfPresent([User.Gender].self, forKey: .meetGender)
		meetNotificationsEnabled = try container.decodePatchOptional(Bool.self, forKey: .meetNotificationsEnabled)
		pronouns = try container.decodeIfPresent([String].self, forKey: .pronouns)
		gender = try container.decodePatchOptional(User.Gender.self, forKey: .gender)
		meetLocation = try container.decodePatchOptional(User.Location.self, forKey: .meetLocation)
		starSign = try container.decodePatchOptional(String.self, forKey: .starSign)
		matchRating = try container.decodePatchOptional(Float.self, forKey: .matchRating)
		allowMatchAudio = try container.decodeIfPresent(Bool.self, forKey: .allowMatchAudio)
		allowMatchImages = try container.decodeIfPresent(Bool.self, forKey: .allowMatchImages)
		allowMatchVideos = try container.decodeIfPresent(Bool.self, forKey: .allowMatchVideos)
		discoverDisabled = try container.decodeIfPresent(Bool.self, forKey: .discoverDisabled)
		hasAgreedToMeetTerms = try container.decodeIfPresent(Bool.self, forKey: .hasAgreedToMeetTerms)
		needsConfirmDOB = try container.decodeIfPresent(Bool.self, forKey: .needsConfirmDOB)
		shouldForceReloadFriends = try container.decodeIfPresent(Bool.self, forKey: .shouldForceReloadFriends)
		hasReducedHonks = try container.decodeIfPresent(Bool.self, forKey: .hasReducedHonks)
		teamNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .teamNotificationsEnabled)
		streakNotificationsDisabled = try container.decodeIfPresent(Bool.self, forKey: .streakNotificationsDisabled)
		hasReducedNotifications = try container.decodeIfPresent(Bool.self, forKey: .hasReducedNotifications)
		topPicksNotificationEnabled = try container.decodeIfPresent(Bool.self, forKey: .topPicksNotificationEnabled)
		feelingLuckyNotificationEnabled = try container.decodeIfPresent(Bool.self, forKey: .feelingLuckyNotificationEnabled)
		honkButton = try container.decodeIfPresent(User.HonkButtonCategory.self, forKey: .honkButton)
	}
}

extension Where<User> {
	func update(apply patch: AccountUpdateRequest) -> UpdateOf<User> {
		update {
			if let name = patch.name { $0.name = name }
			if let username = patch.username { $0.username = username }

			if let avatarURL = patch.avatarURL { $0.avatarUrl = avatarURL }
			if let avatarBlurHash = patch.avatarBlurHash { $0.avatarBlurHash = avatarBlurHash }

			if let birthday = patch.birthday { $0.birthday = birthday }

			if let isNotificationsEnabled = patch.isNotificationsEnabled { $0.isNotificationsEnabled = isNotificationsEnabled }
			if let allowFriendRequests = patch.allowFriendRequests { $0.allowFriendRequests = allowFriendRequests }
			if let showInSuggested = patch.showInSuggested { $0.showInSuggested = showInSuggested }

			if let preferredEmojiSkinTone = patch.preferredEmojiSkinTone { $0.preferredEmojiSkinTone = preferredEmojiSkinTone ?? .default }

			if let reactionEmojis = patch.reactionEmojis { $0.reactionEmojis = #bind(reactionEmojis) }
			if let quickReaction = patch.quickReaction { $0.quickReaction = quickReaction }

			if let bio = patch.bio { $0.bio = bio }
			if let bioColor = patch.bioColor { $0.bioColor = #bind(bioColor) }

			if let status = patch.status { $0.status = status }
			if let statusEmoji = patch.statusEmoji { $0.statusEmoji = statusEmoji }

			if let statusTimeout = patch.statusTimeout { $0.statusTimeout = statusTimeout }
			if let statusClearValue = patch.statusClearValue { $0.statusClearValue = statusClearValue }

			if let meetNotifyEnabled = patch.meetNotifyEnabled { $0.meetNotifyEnabled = meetNotifyEnabled }
			if let meetInterests = patch.meetInterests { $0.meetInterests = #bind(meetInterests ?? []) }
			if let meetGender = patch.meetGender { $0.meetGender = #bind(meetGender) }
			if let meetNotificationsEnabled = patch.meetNotificationsEnabled { $0.meetNotificationsEnabled = meetNotificationsEnabled }

			if let pronouns = patch.pronouns { $0.pronouns = #bind(pronouns) }
			if let gender = patch.gender { $0.gender = gender }
			if let meetLocation = patch.meetLocation { $0.meetLocation = #bind(meetLocation) }

			if let starSign = patch.starSign { $0.starSign = starSign }
			if let matchRating = patch.matchRating { $0.matchRating = matchRating }

			if let allowMatchAudio = patch.allowMatchAudio { $0.allowMatchAudio = allowMatchAudio }
			if let allowMatchImages = patch.allowMatchImages { $0.allowMatchImages = allowMatchImages }
			if let allowMatchVideos = patch.allowMatchVideos { $0.allowMatchVideos = allowMatchVideos }

			if let discoverDisabled = patch.discoverDisabled { $0.discoverDisabled = discoverDisabled }

			if let hasAgreedToMeetTerms = patch.hasAgreedToMeetTerms { $0.hasAgreedMeetTerms = hasAgreedToMeetTerms }
			if let needsConfirmDOB = patch.needsConfirmDOB { $0.needsConfirmDOB = needsConfirmDOB }

			// TODO: Do we need to store this? What does it do?
//			if let shouldForceReloadFriends = patch.shouldForceReloadFriends { $0.shouldForceReloadFriends = shouldForceReloadFriends }

			if let hasReducedHonks = patch.hasReducedHonks { $0.hasReducedHonks = hasReducedHonks }
			if let teamNotificationsEnabled = patch.teamNotificationsEnabled { $0.teamNotificationsEnabled = teamNotificationsEnabled }
			if let streakNotificationsDisabled = patch.streakNotificationsDisabled { $0.streakNotificationsDisabled = streakNotificationsDisabled }
			if let hasReducedNotifications = patch.hasReducedNotifications { $0.hasReducedNotifications = hasReducedNotifications }
			if let topPicksNotificationEnabled = patch.topPicksNotificationEnabled { $0.topPicksNotificationEnabled = topPicksNotificationEnabled }
			if let feelingLuckyNotificationEnabled = patch.feelingLuckyNotificationEnabled { $0.feelingLuckyNotificationEnabled = feelingLuckyNotificationEnabled }

			if let honkButton = patch.honkButton { $0.honkButton = honkButton }
		}
	}
}
