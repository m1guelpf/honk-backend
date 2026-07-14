import Foundation
import MetaCodable
import Dependencies

enum ServerEvent: Sendable {
	case ready
	case pong(Pong)
	case friendPing(FriendPing)
	case screenshot(Screenshot)
	case chatMessage(ChatMessage)
	case userDeclined(CallRequest)
	case chatReaction(ChatReaction)
	case callRequested(CallRequest)
	case userJoinedCall(UserJoinedCall)
	case updateApplicationBadge(UpdateBadge)
}

// MARK: - Event Payloads

extension ServerEvent {
	struct Ready: Equatable, Hashable, Codable, Sendable {}

	struct UpdateBadge: Equatable, Hashable, Codable, Sendable {
		var count: Int
	}

	struct Screenshot: Equatable, Hashable, Codable, Sendable {
		var from: User.ID
	}

	struct Pong: Equatable, Hashable, Codable, Sendable {
		var ping_id: Int
	}

	struct UserJoinedCall: Equatable, Hashable, Codable, Sendable {
		var callId: String
		var userId: String
		var friendshipId: String
	}

	struct FriendPing: Equatable, Hashable, Codable, Sendable {
		var userId: String
		var isOnline: Bool
		var ping_id: Int? = nil
		var callId: String? = nil
		var isOnCall: Bool? = nil
		var isInChat: String? = nil
		var appIsActive: Bool? = nil
		var isOnScreen: String? = nil
		var averagePingTimes: Double? = nil
	}

	struct ChatMessage: Equatable, Hashable, Codable, Sendable {
		var date: Int
		var from: User.ID
		var message: String
		var isFromTemporary: Bool
	}

	struct ChatReaction: Equatable, Hashable, Codable, Sendable {
		var from: User.ID
		var message: String
		var coords: String?
		var trigger: String?
	}

	struct CallRequest: Equatable, Hashable, Codable, Sendable {
		var callId: String
		var userId: String

		/// decline reason
		var reasoning: String?
	}
}

// MARK: - Constructors

extension ServerEvent {
	static func pong(pingId: Int) -> Self {
		.pong(Pong(ping_id: pingId))
	}

	static func screenshot(from userID: User.ID) -> Self {
		.screenshot(Screenshot(from: userID))
	}

	static func callRequested(callId: String, userId: String, reasoning: String? = nil) -> Self {
		.callRequested(CallRequest(callId: callId, userId: userId, reasoning: reasoning))
	}

	static func userDeclined(callId: String, userId: String, reasoning: String? = nil) -> Self {
		.userDeclined(CallRequest(callId: callId, userId: userId, reasoning: reasoning))
	}

	static func userJoinedCall(callId: String, userId: String, friendshipId: String) -> Self {
		.userJoinedCall(UserJoinedCall(callId: callId, userId: userId, friendshipId: friendshipId))
	}
}

// MARK: - Conversion Helpers

extension ServerEvent.FriendPing {
	init(from ping: APIPresence, by userID: User.ID) {
		userId = userID
		callId = ping.callId
		ping_id = ping.ping_id
		isOnline = ping.isOnline
		isOnCall = ping.isOnCall
		isInChat = ping.isInChat
		isOnScreen = ping.isOnScreen
		appIsActive = ping.appIsActive
		averagePingTimes = ping.averagePingTimes
	}
}

extension ServerEvent.ChatMessage {
	init(from message: ClientEvent.ChatMessage, by userID: User.ID) {
		@Dependency(\.date.now) var now

		from = userID
		date = Int(now.timeIntervalSince1970 * 1000)
		self.message = message.message
		isFromTemporary = message.isFromTemporary
	}
}

extension ServerEvent.ChatReaction {
	init(from reaction: ClientEvent.ChatReaction, by userID: User.ID) {
		from = userID
		coords = reaction.coords
		message = reaction.message
		trigger = reaction.trigger
	}
}

// MARK: - Codable

extension ServerEvent: Encodable {
	enum CodingKeys: String, CodingKey {
		case type, data
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
			case .ready:
				try container.encode("ready", forKey: .type)
			case let .updateApplicationBadge(badge):
				try container.encode("badge_count", forKey: .type)
				try badge.encode(to: encoder)
			case let .pong(pong):
				try container.encode("app_pong", forKey: .type)
				try pong.encode(to: encoder)
			case let .userJoinedCall(callJoined):
				try container.encode("user_joined", forKey: .type)
				try callJoined.encode(to: encoder)
			case let .screenshot(screenshot):
				try container.encode("screenshot_from", forKey: .type)
				try screenshot.encode(to: encoder)
			case let .friendPing(ping):
				try container.encode("friend_ping", forKey: .type)
				try container.encode(ping, forKey: .data)
			case let .chatMessage(message):
				try container.encode("chat_message_from", forKey: .type)
				try message.encode(to: encoder)
			case let .chatReaction(reaction):
				try container.encode("chat_reaction_from", forKey: .type)
				try reaction.encode(to: encoder)
			case let .callRequested(callRequest):
				try container.encode("call_requested", forKey: .type)
				try callRequest.encode(to: encoder)
			case let .userDeclined(callRequest):
				try container.encode("user_declined", forKey: .type)
				try callRequest.encode(to: encoder)
		}
	}
}
