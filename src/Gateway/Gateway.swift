import Logging
import Foundation
import SQLiteData
import Dependencies

actor Gateway {
	static let logger = Logger(label: "Gateway")

	private var cachedFriends: [User.ID: Set<User.ID>] = [:]
	private var userPresence: [User.ID: APIPresence?] = [:]
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

	func areOnline(userIDs: [User.ID]) -> [User.ID: Bool] {
		userIDs.reduce(into: [:]) { result, userID in
			result[userID] = isOnline(userID: userID)
		}
	}

	func broadcast(ping: APIPresence, forUser userID: User.ID) {
		userPresence[userID] = ping

		for friend in cachedFriends[userID] ?? [] {
			send(.friendPing(.init(from: ping, by: userID)), to: friend)
		}
	}

	// MARK: - Connection

	func register(userID: User.ID, id: UUID, continuation: AsyncStream<ServerEvent>.Continuation) {
		connections[userID, default: [:]][id] = continuation

		do {
			let friends = try database.read { db in
				try User.find(userID).join(Friendship.all) { $1.involves($0.id) }.select { $1.friendId(besides: userID) }.fetchAll(db)
			}

			cachedFriends[userID] = Set(friends)
		} catch {
			Self.logger.error("Failed to fetch friends for user \(userID): \(error)", error: error)
		}
	}

	func unregister(userID: User.ID, id: UUID) {
		connections[userID]?.removeValue(forKey: id)

		if connections[userID]?.isEmpty == true {
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
