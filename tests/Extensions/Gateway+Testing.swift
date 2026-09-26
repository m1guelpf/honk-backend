@testable import HonkBackend
import Dependencies

extension Gateway {
	@discardableResult func test<E>(
		actingAs userID: User.ID,
		run block: @Sendable (isolated Gateway) async throws(E) -> Void
	) async throws(E) -> AsyncStream<ServerEvent> {
		@Dependency(\.uuid) var uuid

		let id = uuid()
		let (events, continuation) = AsyncStream.makeStream(of: ServerEvent.self)
		defer {
			unregister(userID: userID, id: id)
			continuation.finish()
		}

		register(userID: userID, id: id, continuation: continuation)
		try await block(self)

		return events
	}
}
