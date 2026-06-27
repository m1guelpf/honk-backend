import Foundation
import SQLiteData
import Hummingbird

struct APIFriendInfo: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var _id: String
	var firebaseAuthId: String
	var createdAt: Date
	var name: String
	var username: String
	var avatarURL: URL?
	var avatarBlurHash: String?
	var isOnline: Bool?
	var lastOnlineAt: Date?
	var verified: Bool?
	var bio: String?
	var bioColor: User.BioColor?
	var status: String?
	var statusEmoji: String?
	var stats: User.Stats?
	var emojiSkinTone: User.EmojiSkinTone?
	var birthday: Date?
	var mutualFriends: Int?
	var totalFriends: Int?
	var allowFriendRequests: Bool?
	var isBlocked: Bool?
	var blockedYou: Bool?
	var appVersion: String?
	var fromContacts: Bool?
	var meetInterests: [String]?
	var meetLocation: User.Location?
	var meetGender: [User.Gender]?
	var pronouns: [String]?
	var gender: User.Gender?
	var starSign: String?
	var matchRating: Float?
	var matchPercentage: String?
	var compliments: [String: Int]?
	var allowMatchImages: Bool?
	var allowMatchAudio: Bool?
	var allowMatchVideos: Bool?
	var discoverDisabled: Bool?
	var hasLowRating: Bool?
	var honkButton: User.HonkButtonCategory?
}

extension APIFriendInfo {
	@Selection struct Context {
		var isBlocked: Bool
		var blockedYou: Bool
		var totalFriends: Int
		var mutualFriends: Int
		var fromContacts: Bool
		var appVersion: String?
	}

	init(from user: User, with context: Context, compliments: [String: Int] = [:]) {
		_id = user.id
		firebaseAuthId = user.firebaseUid
		createdAt = user.createdAt
		name = user.name
		username = user.username
		avatarURL = user.avatarUrl
		avatarBlurHash = user.avatarBlurHash
		lastOnlineAt = user.lastOnlineAt
		verified = user.isVerified
		bio = user.bio
		bioColor = user.bioColor
		status = user.status
		statusEmoji = user.statusEmoji
		stats = user.stats
		emojiSkinTone = user.preferredEmojiSkinTone
		birthday = user.birthday
		mutualFriends = context.mutualFriends
		totalFriends = context.totalFriends
		allowFriendRequests = user.allowFriendRequests
		isBlocked = context.isBlocked
		blockedYou = context.blockedYou
		appVersion = context.appVersion
		fromContacts = context.fromContacts
		meetInterests = user.meetInterests
		meetLocation = user.meetLocation
		meetGender = user.meetGender
		pronouns = user.pronouns
		gender = user.gender
		starSign = user.starSign
		matchRating = user.matchRating
		self.compliments = compliments
		allowMatchImages = user.allowMatchImages
		allowMatchAudio = user.allowMatchAudio
		allowMatchVideos = user.allowMatchVideos
		discoverDisabled = user.discoverDisabled
		honkButton = user.honkButton

		// TODO: Fill these in with real data
		isOnline = false // ??????
		hasLowRating = false // ?????
		matchPercentage = nil // ?????
	}
}

// MARK: - From Query

extension SelectStatement where From == User, Joins == (), QueryValue == () {
	func selectAsFriendInfo(viewedBy me: User, friendIds: [User.ID]) -> some SelectStatement<(User, APIFriendInfo.Context), User, Void> {
		asSelect().select { user in
			let isBlocked = Block.where { $0.id.blockerId.eq(me.id) && $0.id.blockedId.eq(user.id) }.exists()
			let blockedYou = Block.where { $0.id.blockerId.eq(user.id) && $0.id.blockedId.eq(me.id) }.exists()

			let totalFriends = Friendship.where {
				$0.state.eq("accepted") && ($0.userLowId.eq(user.id) || $0.userHighId.eq(user.id))
			}
			.count()

			let mutualFriends = Friendship.where {
				$0.state.eq("accepted")
					&& (($0.userLowId.eq(user.id) && $0.userHighId.in(friendIds))
						|| ($0.userHighId.eq(user.id) && $0.userLowId.in(friendIds)))
			}
			.count()

			let fromContacts = ContactHash.where {
				$0.id.userFirebaseUid.eq(me.firebaseUid) && $0.id.hash.is(user.contactHash)
			}
			.exists()

			let appVersion = Device.where { $0.id.userId.eq(user.id) }
				.order { $0.updatedAt.desc() }
				.limit(1)
				.select { $0.appVersion.cast(as: String?.self) }

			return (user, APIFriendInfo.Context.Columns(
				isBlocked: isBlocked,
				blockedYou: blockedYou,
				totalFriends: totalFriends,
				mutualFriends: mutualFriends,
				fromContacts: fromContacts,
				appVersion: appVersion
			))
		}
	}
}
