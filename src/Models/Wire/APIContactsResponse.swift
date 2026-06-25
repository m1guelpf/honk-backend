import Foundation
import Hummingbird

struct APIContactsResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	struct DecoratedContact: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		var contact: String
		var friendCount: Int
	}

	var contacts: [DecoratedContact]
}
