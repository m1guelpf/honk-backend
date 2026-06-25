import Foundation
import Hummingbird

struct ValidatePhoneRequest: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var number: String
}
