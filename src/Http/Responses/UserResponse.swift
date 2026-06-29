import Foundation
import Hummingbird

struct UserResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var user: APIUserInfo
}
