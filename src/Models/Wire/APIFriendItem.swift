import Foundation
import Hummingbird

struct APIFriendItem: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var requestMessage: String?
	var friendship: APIFriendshipInfo
	var chat: APIChatInfo
	var friend: APIFriendInfo
}
