import Foundation
import Hummingbird

struct FriendsOnHonkResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var users: [APIFriendInfo]
	var moreContactsAvailable: Bool
	var lastPageRequested: Int
}
