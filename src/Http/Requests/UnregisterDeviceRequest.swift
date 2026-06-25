import Foundation
import Hummingbird

struct UnregisterDeviceRequest: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var unregisterToken: String
}
