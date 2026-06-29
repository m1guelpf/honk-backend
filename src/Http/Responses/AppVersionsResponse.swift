import Foundation
import Hummingbird

struct AppVersionsResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var versions: [String]
}
