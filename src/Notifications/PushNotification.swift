import Foundation

/// A push notification the server delivers to a device via APNs.
enum PushNotification: Sendable {
	// MARK: Conversation activity

	case typing(from: User.ID, senderName: String, chatId: Conversation.ID, lastActiveInChat: Date? = nil)
	case honk(from: User.ID, senderName: String, chatId: Conversation.ID, lastActiveInChat: Date? = nil)
	case message(from: User.ID, senderName: String, chatId: Conversation.ID, lastActiveInChat: Date? = nil)
	case reaction(from: User.ID, senderName: String, chatId: Conversation.ID, emoji: String, lastActiveInChat: Date? = nil)
	case asset(from: User.ID, senderName: String, chatId: Conversation.ID, kind: Asset.Kind, lastActiveInChat: Date? = nil)
	/// The other side started playing your voice/video message.
	case listening(from: User.ID, senderName: String, chatId: Conversation.ID, lastActiveInChat: Date? = nil)
	/// The other side started recording a voice/video message.
	case recording(from: User.ID, senderName: String, chatId: Conversation.ID, lastActiveInChat: Date? = nil)

	// MARK: Friendships

	case friendRequest(from: User.ID, senderName: String, chatId: Conversation.ID)
	case friendAccept(from: User.ID, senderName: String, chatId: Conversation.ID)
}

// MARK: - Presentation

extension PushNotification {
	/// What the user actually sees.
	struct Alert: Equatable, Hashable, Sendable {
		var title: String
		var body: String
		var sound: String?
		var badge: Int?

		init(title: String, body: String, sound: String? = nil, badge: Int? = nil) {
			self.title = title
			self.body = body
			self.sound = sound
			self.badge = badge
		}
	}

	var alert: Alert? {
		switch self {
			case let .typing(_, senderName, _, _):
				Alert(title: senderName, body: "Typing…", sound: "typing push notification.wav")
			case let .honk(_, senderName, _, _):
				Alert(title: senderName, body: "Honk! 📣", sound: "honk receive push notification.wav")
			case let .message(_, senderName, _, _):
				Alert(title: senderName, body: "Sent you a message 💬", sound: "honk receive push notification.wav")
			case let .reaction(_, senderName, _, emoji, _):
				Alert(title: senderName, body: "Reacted with \(emoji)", sound: "honk receive push notification.wav")
			case let .asset(_, senderName, _, kind, _):
				switch kind {
					case .video: Alert(title: senderName, body: "Sent you a video 📹", sound: "honk-video-send-notification.wav")
					case .audio: Alert(title: senderName, body: "Sent you a voice message 🎤", sound: "they record audio push notification.wav")
					default: Alert(title: senderName, body: "Sent you a photo 📷", sound: "photo push notification.wav")
				}
			case let .listening(_, senderName, _, _):
				Alert(title: senderName, body: "Listening to your message 🎧", sound: "they play audio push notification.wav")
			case let .recording(_, senderName, _, _):
				Alert(title: senderName, body: "Recording a message 🎤", sound: "they record audio push notification.wav")
			case let .friendRequest(_, senderName, _):
				Alert(title: senderName, body: "Sent you a friend request 👋", sound: "friend requested you push notification.wav")
			case let .friendAccept(_, senderName, _):
				Alert(title: senderName, body: "Accepted your friend request 🎉", sound: "friend request accepted.wav")
		}
	}
}

// MARK: - Codable

extension PushNotification: Encodable {
	/// The `notif_type` discriminator the client switches on.
	var notifType: String {
		switch self {
			case .typing: "typing"
			case .honk: "honk"
			case .message: "fromUser"
			case .reaction: "reaction"
			case let .asset(_, _, _, kind, _):
				switch kind {
					case .video: "chatVideo"
					case .audio: "fromUser"
					default: "chatImage"
				}
			case .listening: "listening"
			case .recording: "recording"
			case .friendRequest: "friendRequest"
			case .friendAccept: "friendAccept"
		}
	}

	enum CodingKeys: String, CodingKey {
		case chatId = "chat_id"
		case userId = "user_id"
		case notifType = "notif_type"
		case maxVersion = "max_version"
		case suggestionStackId = "suggestion_stack_id"
		case screenID, callId, friendshipId, complimentId, unlocked, unlockType, gameId, gameType, lastActiveInChat
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(notifType, forKey: .notifType)

		switch self {
			case let .typing(from, _, chatId, lastActiveInChat), let .honk(from, _, chatId, lastActiveInChat),
			     let .message(from, _, chatId, lastActiveInChat), let .listening(from, _, chatId, lastActiveInChat),
			     let .recording(from, _, chatId, lastActiveInChat), let .reaction(from, _, chatId, _, lastActiveInChat),
			     let .asset(from, _, chatId, _, lastActiveInChat):
				try container.encode(from, forKey: .userId)
				try container.encode(chatId, forKey: .chatId)
				try container.encodeIfPresent(lastActiveInChat?.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true)), forKey: .lastActiveInChat)
			case let .friendRequest(from, _, chatId), let .friendAccept(from, _, chatId):
				try container.encode(from, forKey: .userId)
				try container.encode(chatId, forKey: .chatId)
		}
	}
}
