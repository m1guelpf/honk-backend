import Foundation
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
	var emojiSkinTone: String?
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
