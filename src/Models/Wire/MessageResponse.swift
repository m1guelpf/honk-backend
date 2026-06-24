import Foundation
import Hummingbird

struct MessageResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var message: String
}
