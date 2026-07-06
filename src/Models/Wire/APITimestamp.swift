import Foundation
import Hummingbird

struct APITimestamp: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var milliseconds: Int
}
