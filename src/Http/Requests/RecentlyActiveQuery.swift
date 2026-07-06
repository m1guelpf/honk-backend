import Foundation
import Hummingbird

struct RecentlyActiveQuery: Decodable, Sendable {
	var amountOfFriends: Int

	enum CodingKeys: String, CodingKey {
		case amountOfFriends
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let amount = try container.decodeIfPresent(Int.self, forKey: .amountOfFriends) ?? 20
		amountOfFriends = min(max(amount, 1), 100)
	}
}
