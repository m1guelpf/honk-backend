import Foundation
import Hummingbird

struct ContactsLinkRequest: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var contacts: [String]
}
