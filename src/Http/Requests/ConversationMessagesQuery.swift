import Foundation
import Hummingbird

struct ConversationMessagesQuery: Sendable {
	var includeYourMessage: Bool
}

extension ConversationMessagesQuery: Decodable {
	private enum CodingKeys: String, CodingKey {
		case includeYourMessage
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		includeYourMessage = try container.decodeIfPresent(Bool.self, forKey: .includeYourMessage) ?? false
	}
}
