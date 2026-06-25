import Foundation
import Hummingbird

struct FriendsOnHonkResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var users: [APIFriendInfo]
}
