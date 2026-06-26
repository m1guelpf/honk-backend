import Foundation
import Hummingbird

struct ConfirmPhoneRequest: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var number: String
	var code: String
}
