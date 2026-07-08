import Foundation
import Hummingbird

struct ChatFriendshipResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	struct Presence: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		var ping_id: Int?
		var isOnline: Bool
		var isInChat: String?
		var isOnScreen: String?
		var callId: String?
		var isOnCall: Bool?
		var appIsActive: Bool?
		var averagePingTimes: Double?
	}

	var isInChat: Bool?
	var isOnScreen: String?
	var friendship: APIFriendshipInfo
	var chat: APIChatInfo
	var friend: APIFriendInfo?
	var presence: Presence?
}
