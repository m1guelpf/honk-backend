import Foundation
import Hummingbird

struct APISentCompliment: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var complimentId: String
	var createdAt: Date
}
