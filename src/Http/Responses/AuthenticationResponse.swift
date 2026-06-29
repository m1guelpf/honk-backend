import Foundation
import Hummingbird

struct AuthenticationResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var token: String
	var expiresAt: Date
	var user: APIUserInfo?
}
