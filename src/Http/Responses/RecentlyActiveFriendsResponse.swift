import Foundation
import SQLiteData
import Hummingbird

struct RecentlyActiveFriendsResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	@Selection
	struct RecentlyActiveFriend: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		var firebaseAuthId: String
		var lastOnlineAt: Date
	}

	var lastActive: [RecentlyActiveFriend]
}
