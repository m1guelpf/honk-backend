import Foundation
import Hummingbird

struct APIFriendConversation: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var friendId: String
	var theirMessage: String?
	var yourMessage: String?
	var theirDate: APITimestamp?
	var yourDate: APITimestamp?
}
