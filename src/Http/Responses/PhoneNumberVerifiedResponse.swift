import Foundation
import Hummingbird

struct PhoneNumberVerifiedResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var contactHash: String
}
