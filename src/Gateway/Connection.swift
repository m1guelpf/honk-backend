import Logging
import NIOCore
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

	private func handleEvent(_ event: ClientEvent, connection: AsyncStream<ServerEvent>.Continuation) async throws {
		switch event {
			case let .ping(ping):
				// TODO: Store presence?
				connection.yield(.pong(pingId: ping.ping_id))
				try await gateway.broadcast(ping: ping, forUser: userID)
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
			case let .chatAudioState(audioState):
				@Dependency(\.defaultDatabase) var database
				guard let row = try await database.read({ db in
					try Conversation.between(userID, and: audioState.to)
						.join(ConversationMember.all) { $1.id.conversationId.eq($0.id) && $1.id.userId.eq(userID) }
						.join(User.all) { $2.id.eq(audioState.to) }
						.select { ($0, $1, $2, $2.asFriendContext(viewedBy: userID)) }
						.fetchOne(db)
				}) else { return }

				let (conversation, member, user, userContext) = row
				await gateway.run {
					let friend = APIFriendInfo(from: user, with: userContext, isOnline: $0.isOnline(userID: audioState.to))

					$0.send(.chatUpdate(.init(key: conversation.id, data: APIChatInfo(from: conversation, with: .init(friend: friend, member: member, friendAudioState: audioState.state)))), to: audioState.to)
				}
			case let .chatAsset(chatAsset):
				await gateway.send(.chatAsset(.init(from: chatAsset, by: userID)), to: chatAsset.to)

				if chatAsset.shouldPersist == true {
					try await ConversationAsset.persist(chatAsset, from: userID)
				}
		}
	}
}
