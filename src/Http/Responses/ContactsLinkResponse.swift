import Foundation
import Hummingbird

struct ContactsLinkResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var items: [String]
}
