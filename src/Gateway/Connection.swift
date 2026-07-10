import NIOCore
import Logging
import Foundation
import Dependencies
import HummingbirdWebSocket

struct Connection {
	static let logger = Logger(label: "Connection")

	let userID: User.ID

	@Dependency(\.gateway) private var gateway

	func run(inbound: WebSocketInboundStream, outbound: WebSocketOutboundWriter) async {
		let (events, continuation) = AsyncStream.makeStream(of: ServerEvent.self)
		let connectionID = UUID()

		await gateway.register(userID: userID, id: connectionID, continuation: continuation)

		continuation.yield(.ready)

		await withTaskGroup(of: Void.self) { group in
			group.addTask {
				let encoder = JSONEncoder()
				encoder.dateEncodingStrategy = .honk

				for await event in events {
					try? await outbound.write(.binary(
						ByteBuffer(data: encoder.encode(event))
					))
				}
			}

			group.addTask {
				let decoder = JSONDecoder()
				decoder.dateDecodingStrategy = .honk

				do {
					for try await message in inbound.messages(maxSize: 1 << 20) {
						guard case let .binary(frame) = message else { continue }

						let event = try decoder.decode(ClientEvent.self, from: frame)
						handleEvent(event, connection: continuation)
					}
				} catch {
					if error is DecodingError {
						Self.logger.warning("Failed to decode event: \(error)", error: error)
					}
				}

				continuation.finish()
			}

			await group.waitForAll()
		}

		await gateway.unregister(userID: userID, id: connectionID)
	}

	private func handleEvent(_ event: ClientEvent, connection: AsyncStream<ServerEvent>.Continuation) {
		switch event {
			case let .ping(ping): connection.yield(.pong(pingId: ping.ping_id))
		}
	}
}
