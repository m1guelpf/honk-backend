import Foundation
import Hummingbird

struct APIFriendConversation: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var friendId: String
	var yourMessage: String?
	var theirMessage: String?
	var yourDate: APITimestamp?
	var theirDate: APITimestamp?
}

extension APIFriendConversation {
	init(friendId: String, theirMessage: Message?, yourMessage: Message?) {
		self.friendId = friendId
		self.yourMessage = yourMessage?.text
		self.theirMessage = theirMessage?.text
		yourDate = (yourMessage?.updatedAt as Date?).map { APITimestamp($0) }
		theirDate = (theirMessage?.updatedAt as Date?).map { APITimestamp($0) }
	}
}
