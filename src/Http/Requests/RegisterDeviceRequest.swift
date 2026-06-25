import Foundation
import Hummingbird

struct RegisterDeviceRequest: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var deviceId: String
	var sandbox: Bool
	var voipToken: String?
	var notificationToken: String?
}
