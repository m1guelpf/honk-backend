import Foundation
import Hummingbird

struct FriendUpdatesQuery: Sendable {
	var lastCollected: Date
}

extension FriendUpdatesQuery: Decodable {
	private enum CodingKeys: String, CodingKey {
		case lastCollected
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let rawDate = try container.decode(String.self, forKey: .lastCollected)

		do {
			lastCollected = try Date(honk: rawDate)
		} catch {
			throw DecodingError.dataCorruptedError(forKey: .lastCollected, in: container, debugDescription: "Invalid date format")
		}
	}
}
