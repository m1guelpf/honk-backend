import Foundation
import SQLiteData
import Hummingbird

struct APIContactsResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	@Selection
	struct DecoratedContact: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		var contact: String
		var friendCount: Int
	}

	var contacts: [DecoratedContact]
	var moreContactsAvailable: Bool
	var lastPageRequested: Int
}
