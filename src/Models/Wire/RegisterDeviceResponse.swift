import Foundation
import Hummingbird

struct RegisterDeviceResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var unregisterToken: String
}
