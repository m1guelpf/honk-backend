import Foundation
import MetaCodable

@Codable @CodedAt("type")
enum ClientEvent: Sendable {
	@CodedAs("app_ping")
	case ping(APIPresence)

	@CodedAs("chat_honk")
	case honk(Honk)

	@CodedAs("chat_message_to")
	case chatMessage(ChatMessage)

	@CodedAs("screenshot_to")
	case screenshot(Screenshot)

	@CodedAs("chat_reaction_to")
	case chatReaction(ChatReaction)

	@CodedAs("chat_asset_to")
	case chatAsset(ChatAsset)
}

extension ClientEvent {
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

	struct ChatAsset: Equatable, Hashable, Codable, Sendable {
		var to: User.ID
		var asset: String? // unclear what goes here, `==`
		var shouldPersist: Bool?
		var isFromTemporary: Bool
		var data: Asset.Parameters
	}
