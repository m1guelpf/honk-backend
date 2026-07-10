import Foundation
import MetaCodable

@Codable @CodedAt("type")
enum ServerEvent: Sendable {
	@CodedAs("ready")
	case ready(Ready)

	@CodedAs("app_pong")
	case pong(Pong)

	case presence(Presence)

	@CodedAs("user_joined")
	case userJoined(UserJoined)

	@CodedAs("friend_ping")
	case friendPing(FriendPing)

	@CodedAs("chat_message_from")
	case chatMessage(ChatMessage)

	@CodedAs("call_requested")
	case callRequested(CallRequest)

	@CodedAs("user_declined")
	case userDeclined(CallRequest)
}

// MARK: - Event Payloads

extension ServerEvent {
	struct Ready: Equatable, Hashable, Codable, Sendable {}

	struct Pong: Equatable, Hashable, Codable, Sendable {
		var ping_id: Int
	}

	struct Presence: Equatable, Hashable, Codable, Sendable {
		var isViewing: Bool
		var screen: String
	}

	struct UserJoined: Equatable, Hashable, Codable, Sendable {
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
		var content: String
		var timestamp: Date
		var isOriginal: Bool
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
	static var ready: Self {
		.ready(Ready())
	}

	static func pong(pingId: Int) -> Self {
		.pong(Pong(ping_id: pingId))
	}

	static func chatMessage(content: String, timestamp: Date, isOriginal: Bool) -> Self {
		.chatMessage(ChatMessage(content: content, timestamp: timestamp, isOriginal: isOriginal))
	}

	static func presence(isViewing: Bool, screen: String) -> Self {
		.presence(Presence(isViewing: isViewing, screen: screen))
	}

	static func callRequested(callId: String, userId: String, reasoning: String? = nil) -> Self {
		.callRequested(CallRequest(callId: callId, userId: userId, reasoning: reasoning))
	}

	static func userDeclined(callId: String, userId: String, reasoning: String? = nil) -> Self {
		.userDeclined(CallRequest(callId: callId, userId: userId, reasoning: reasoning))
	}

	static func userJoined(callId: String, userId: String, friendshipId: String) -> Self {
		.userJoined(UserJoined(callId: callId, userId: userId, friendshipId: friendshipId))
	}

	static func friendPing(
		userId: String,
		isOnline: Bool,
		pingId: Int? = nil,
		isInChat: String? = nil,
		isOnScreen: String? = nil,
		callId: String? = nil,
		isOnCall: Bool? = nil,
		appIsActive: Bool? = nil,
		averagePingTimes: Double? = nil
	) -> Self {
		.friendPing(FriendPing(
			userId: userId, isOnline: isOnline, ping_id: pingId, callId: callId, isOnCall: isOnCall,
			isInChat: isInChat, appIsActive: appIsActive, isOnScreen: isOnScreen, averagePingTimes: averagePingTimes
		))
	}
}
