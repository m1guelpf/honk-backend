import Foundation
import Hummingbird

struct LoginWithTokenRequest: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var isTestToken: Bool
	var token: String
}
