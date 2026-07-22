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
	var starSign: User.StarSign?
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

	init(from user: User, with context: Context, compliments: [String: Int] = [:], isOnline: Bool) {
		_id = user.id
		firebaseAuthId = user.id
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
		self.isOnline = isOnline

		hasLowRating = false // ?????
		matchPercentage = nil // ?????
	}
}

// MARK: - From Query

extension User.TableColumns {
	func asFriendContext(viewedBy userID: User.ID) -> some QueryExpression<APIFriendInfo.Context> {
		let isBlocked = Block.where { $0.isFrom(userID, to: self.id) }.exists()
		let blockedYou = Block.where { $0.isFrom(self.id, to: userID) }.exists()

		let totalFriends = Friendship.where {
			$0.state.eq(Friendship.State.accepted) && $0.involves(self.id)
		}
		.count()

		let myFriendIds = Friendship
			.where { $0.state.eq(Friendship.State.accepted) && $0.involves(userID) }
			.select { $0.friendId(besides: userID) }
		let mutualFriends = Friendship.where {
			$0.state.eq(Friendship.State.accepted)
				&& $0.involves(self.id)
				&& $0.friendId(besides: self.id).in(myFriendIds)
		}
		.count()

		let fromContacts = ContactHash.where {
			$0.id.userFirebaseUid.eq(userID) && $0.id.hash.is(self.contactHash)
		}
		.exists()

		let appVersion = Device.where { $0.id.userId.eq(self.id) }
			.order { $0.updatedAt.desc() }
			.limit(1)
			.select { $0.appVersion }

		return APIFriendInfo.Context.Columns(
			isBlocked: isBlocked,
			blockedYou: blockedYou,
			totalFriends: totalFriends,
			mutualFriends: mutualFriends,
			fromContacts: fromContacts,
			appVersion: appVersion
		)
	}
}

extension SelectStatement where From == User, Joins == (), QueryValue == () {
	func selectAsFriendInfo(viewedBy userID: User.ID) -> some SelectStatement<(User, APIFriendInfo.Context), User, Void> {
		asSelect().select { user in
			(user, user.asFriendContext(viewedBy: userID))
		}
	}
}
