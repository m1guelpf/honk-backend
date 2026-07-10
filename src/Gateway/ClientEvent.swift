import Foundation
import MetaCodable

@Codable @CodedAt("type")
enum ClientEvent: Sendable {
	@CodedAs("app_ping")
	case ping(Ping)
}

extension ClientEvent {
	struct Ping: Equatable, Hashable, Codable, Sendable {
		var ping_id: Int
		var isOnline: Bool
		var appIsActive: Bool
	}
}
