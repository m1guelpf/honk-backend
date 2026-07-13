import Foundation
import MetaCodable

@Codable @CodedAt("type")
enum ClientEvent: Sendable {
	@CodedAs("app_ping")
	case ping(Ping)

	@CodedAs("chat_honk")
	case honk(Honk)

	@CodedAs("chat_message_to")
	case chatMessage(ChatMessage)

	@CodedAs("screenshot_to")
	case screenshot(Screenshot)

	@CodedAs("chat_reaction_to")
	case chatReaction(ChatReaction)
}

extension ClientEvent {
	struct Ping: Equatable, Hashable, Codable, Sendable {
		var ping_id: Int
		var isOnline: Bool
		var callId: String?
		var appIsActive: Bool
		var isOnCall: Bool?
		var isInChat: String?
		var isOnScreen: String?
		var averagePingTimes: Double?
	}

	struct Honk: Equatable, Hashable, Codable, Sendable {
		var to: User.ID
	}

	struct Screenshot: Equatable, Hashable, Codable, Sendable {
		var to: User.ID
	}

	struct ChatMessage: Equatable, Hashable, Codable, Sendable {
		var to: User.ID
		var message: String
		var isFromTemporary: Bool
	}

	struct ChatReaction: Equatable, Hashable, Codable, Sendable {
		var to: User.ID
		var trigger: String?
		var message: String // reaction emoji
		var coords: String? // 0.3280532598714417,0.564968525838091, global emoji if null
	}
	}
}
