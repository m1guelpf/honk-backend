import Foundation
import Hummingbird

struct FriendChatsQuery: Sendable {
	var includeYourMessages: Bool
}

extension FriendChatsQuery: Decodable {
	private enum CodingKeys: String, CodingKey {
		case includeYourMessages
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		includeYourMessages = try container.decodeIfPresent(Bool.self, forKey: .includeYourMessages) ?? false
	}
}
