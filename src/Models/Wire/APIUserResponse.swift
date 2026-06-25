import Foundation
import Hummingbird

struct APIUserResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var user: RawUserAccountInfo
}
