import Foundation
import Hummingbird

struct FriendUpdatesResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	struct Updates: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		var chatUpdates: [APIChatInfo]
		var friendUpdates: [APIFriendInfo]
		var friendshipUpdates: [APIFriendshipInfo]
	}

	var updates: Updates
	var allFriendships: [String]
	var newFriends: [APIFriendItem]
	var allDiscoverFriendships: [String]
}
