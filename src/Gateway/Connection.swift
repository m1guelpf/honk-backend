import NIOCore
import Logging
import Foundation
import SQLiteData
import Dependencies
import HummingbirdWebSocket

struct Connection {
	static let logger = Logger(label: "Connection")

	let userID: User.ID

	@Dependency(\.date.now) private var now
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
						Task {
							do { try await handleEvent(event, connection: continuation) }
							catch { Self.logger.error("Failed to handle event: \(error)", error: error) }
						}
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

	private func handleEvent(_ event: ClientEvent, connection: AsyncStream<ServerEvent>.Continuation) async {
		switch event {
			case let .ping(ping):
				// TODO: Store presence?
				connection.yield(.pong(pingId: ping.ping_id))
				await gateway.broadcast(ping: ping, forUser: userID)
			case let .honk(honk):
				// TODO: Broadcast honks
				print("honked \(honk.to)")
			case let .chatMessage(message):
				await gateway.send(.chatMessage(.init(from: message, by: userID)), to: message.to)
			case let .screenshot(screenshot):
				await gateway.send(.screenshot(from: userID), to: screenshot.to)
			case let .chatReaction(reaction):
				// TODO: Push notification if the user is offline?
				await gateway.send(.chatReaction(.init(from: reaction, by: userID)), to: reaction.to)
		}
	}
}
