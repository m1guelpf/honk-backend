import Foundation
import Hummingbird

struct ChangeLogUserResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var versions: [String]
}
