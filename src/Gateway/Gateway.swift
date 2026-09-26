import Logging
import Foundation
import SQLiteData
import Dependencies

actor Gateway {
	@Selection struct CachedFriend: Hashable {
		let friendID: User.ID
		let friendshipID: Friendship.ID
	}

	static let logger = Logger(label: "Gateway")

	private var userPresence: [User.ID: APIPresence?] = [:]
	private var lastMessageAt: [User.ID: [User.ID: Date]] = [:]
	private var cachedFriends: [User.ID: Set<CachedFriend>] = [:]
	private var connections: [User.ID: [UUID: AsyncStream<ServerEvent>.Continuation]] = [:]

	private init() {}

	@Dependency(\.date.now) private var now
	@Dependency(\.continuousClock) private var clock
	@Dependency(\.chatService) private var chatService
	@Dependency(\.defaultDatabase) private var database

	// MARK: - Presence

	func isOnline(userID: User.ID) -> Bool {
		connections[userID]?.isEmpty == false
	}

	func presence(userID: User.ID) -> APIPresence? {
		userPresence[userID].flatten()
	}

	func activeChat(userID: User.ID) -> Friendship.ID? {
		guard isOnline(userID: userID), let presence = presence(userID: userID), presence.isOnline, presence.appIsActive else { return nil }
		return presence.isInChat
	}

	func broadcast(ping: APIPresence, forUser userID: User.ID) throws {
		userPresence[userID] = ping

		guard let friends = cachedFriends[userID] else {
			let friends = try database.read { db in
				try User.find(userID)
					.join(Friendship.all) { $1.involves($0.id) && $1.state.eq(Friendship.State.accepted) }
					.select { CachedFriend.Columns(friendID: $1.friendId(besides: userID), friendshipID: $1.id) }
					.fetchAll(db)
			}

			cachedFriends[userID] = Set(friends)
			return try broadcast(ping: ping, forUser: userID)
		}

		for friend in friends {
			var ping = ping
			if let chatID = ping.isInChat, chatID != friend.friendshipID {
				ping.isInChat = nil
				ping.isOnScreen = nil
			}

			send(.friendPing(.init(from: ping, by: userID)), to: friend.friendID)
		}

		if ping.isOnline, ping.appIsActive, let chattingWithFriend = ping.isInChat {
			let updatedChat = try database.write { db in
				try ConversationMember
					.where {
						$0.id.userId.eq(userID) && $0.id.conversationId.eq(Conversation.where { $0.friendshipId.eq(chattingWithFriend) }.select(\.id)) && $0.hasUnread
					}
					.update {
						$0.hasUnread = false
						$0.lastReadAt = #bind(now)
					}
					.returning(\.id.conversationId)
					.fetchOne(db)
			}

			if let updatedChat {
				try chatService.sendUpdate(for: updatedChat, to: userID, gateway: self)
			}
		}
	}

	func didFriendsChange(forUser userID: User.ID) {
		cachedFriends.removeValue(forKey: userID)
	}

	// MARK: - Connection

	func register(userID: User.ID, id: UUID, continuation: AsyncStream<ServerEvent>.Continuation) {
		connections[userID, default: [:]][id] = continuation
	}

	func unregister(userID: User.ID, id: UUID) {
		connections[userID]?.removeValue(forKey: id)

		if connections[userID]?.isEmpty == true {
			try? broadcast(ping: APIPresence(ping_id: 0, isOnline: false, appIsActive: false), forUser: userID)

			connections.removeValue(forKey: userID)
			userPresence.removeValue(forKey: userID)
			cachedFriends.removeValue(forKey: userID)
			let timestamps = lastMessageAt[userID]

			_ = Task {
				try await clock.sleep(for: .seconds(0.9))

				if !isOnline(userID: userID), lastMessageAt[userID] == timestamps {
					lastMessageAt[userID] = nil
				}
			}
		}
	}

	func shouldNotifyOfMessage(_ message: ClientEvent.ChatMessage, from sender: User.ID) -> Bool {
		guard !message.message.isEmpty else { return false }

		let date = now
		let previous = lastMessageAt[sender]?[message.to]
		lastMessageAt[sender, default: [:]][message.to] = date

		return previous.map { date.timeIntervalSince($0) >= 0.9 } ?? true
	}

	func send(_ event: ServerEvent, to userID: User.ID) {
		guard let connections = connections[userID], !connections.isEmpty else { return }

		for continuation in connections.values {
			continuation.yield(event)
		}
	}
}

// MARK: - Dependencies

extension Gateway: DependencyKey {
	static let liveValue = Gateway()
	static var testValue: Gateway { Gateway() }
}

extension DependencyValues {
	var gateway: Gateway {
		get { self[Gateway.self] }
		set { self[Gateway.self] = newValue }
	}
}
