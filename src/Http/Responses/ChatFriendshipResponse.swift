import Foundation
import Hummingbird

struct ChatFriendshipResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var isInChat: Bool?
	var isOnScreen: String?
	var friendship: APIFriendshipInfo
	var chat: APIChatInfo
	var friend: APIFriendInfo?
	var presence: APIPresence?
}
