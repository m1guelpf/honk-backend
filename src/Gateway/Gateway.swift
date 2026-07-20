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
	private var cachedFriends: [User.ID: Set<CachedFriend>] = [:]
	private var connections: [User.ID: [UUID: AsyncStream<ServerEvent>.Continuation]] = [:]

	private init() {}

	@Dependency(\.defaultDatabase) private var database

	// MARK: - Presence

	func isOnline(userID: User.ID) -> Bool {
		connections[userID]?.isEmpty == false
	}

	func presence(userID: User.ID) -> APIPresence? {
		userPresence[userID].flatten()
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
		}
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
	static let testValue = Gateway()
}

extension DependencyValues {
	var gateway: Gateway {
		get { self[Gateway.self] }
		set { self[Gateway.self] = newValue }
	}
}
