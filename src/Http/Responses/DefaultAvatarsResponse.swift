import Foundation
import Hummingbird

struct DefaultAvatarsResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var avatars: [String]
}
