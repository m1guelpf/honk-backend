import Foundation
import Hummingbird

struct Color: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var red: Float // 0.0 - 1.0
	var green: Float // 0.0 - 1.0
	var blue: Float // 0.0 - 1.0
	var alpha: Float // 0.0 - 1.0
}
