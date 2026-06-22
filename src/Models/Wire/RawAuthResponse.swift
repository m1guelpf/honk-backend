import Foundation
import Hummingbird

struct RawAuthResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var token: String
	var expiresAt: Date
	var user: RawUserAccountInfo?
}
