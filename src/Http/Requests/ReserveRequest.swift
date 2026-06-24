import Foundation
import Hummingbird

struct ReserveRequest: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var username: String
}
