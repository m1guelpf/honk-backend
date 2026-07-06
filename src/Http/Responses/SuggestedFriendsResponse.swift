import Foundation
import Hummingbird

struct SuggestedFriendsResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var suggested: [APIFriendInfo]
}
