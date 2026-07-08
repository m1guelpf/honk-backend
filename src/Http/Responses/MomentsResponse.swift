import Foundation
import Hummingbird

struct MomentsResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var moments: [APIMoment]
}
