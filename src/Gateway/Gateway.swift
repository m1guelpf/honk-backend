import Foundation
import Dependencies

actor Gateway {
	private var connections: [User.ID: [UUID: AsyncStream<ServerEvent>.Continuation]] = [:]

	private init() {}

	// MARK: - Online Status

	func isOnline(userID: User.ID) -> Bool {
		connections[userID]?.isEmpty == false
	}

	func areOnline(userIDs: [User.ID]) -> [User.ID: Bool] {
		userIDs.reduce(into: [:]) { result, userID in
			result[userID] = isOnline(userID: userID)
		}
	}

	// MARK: - Connection

	func register(userID: User.ID, id: UUID, continuation: AsyncStream<ServerEvent>.Continuation) {
		connections[userID, default: [:]][id] = continuation
	}

	func unregister(userID: User.ID, id: UUID) {
		connections[userID]?.removeValue(forKey: id)
		if connections[userID]?.isEmpty == true { connections.removeValue(forKey: userID) }
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
