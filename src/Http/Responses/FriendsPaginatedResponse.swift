import Foundation
import Hummingbird

struct FriendsPaginatedResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var friends: [APIFriendItem]
	var allFriendships: [String]? = nil
}
