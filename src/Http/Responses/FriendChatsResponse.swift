import Foundation
import Hummingbird

struct FriendChatsResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var chats: [APIFriendConversation]
}
