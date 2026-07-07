import Foundation
import Hummingbird

// TODO: is this missing any optional fields?
struct ChatFriendshipResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var friendship: APIFriendshipInfo
	var chat: APIChatInfo
}
