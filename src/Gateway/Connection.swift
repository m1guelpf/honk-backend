import Logging
import NIOCore
import Foundation
import SQLiteData
import Dependencies
import HummingbirdWebSocket

struct Connection {
	static let logger = Logger(label: "Connection")

	let userID: User.ID

	@Dependency(\.apns) private var apns
	@Dependency(\.date.now) private var now
	@Dependency(\.gateway) private var gateway
	@Dependency(\.chatService) private var chatService
	@Dependency(\.defaultDatabase) private var database

	func run(inbound: WebSocketInboundStream, outbound: WebSocketOutboundWriter) async {
		let (events, continuation) = AsyncStream.makeStream(of: ServerEvent.self)
		let connectionID = UUID()

		await gateway.register(userID: userID, id: connectionID, continuation: continuation)

		continuation.yield(.ready)

		await withTaskGroup(of: Void.self) { group in
			group.addTask {
				let encoder = JSONEncoder.withHonkDateEncoding()

				for await event in events {
					try? await outbound.write(.binary(
						ByteBuffer(data: encoder.encode(event))
					))
				}
			}

			group.addTask {
				let decoder = JSONDecoder.withHonkDateDecoding()

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
				connection.yield(.pong(pingId: ping.ping_id))
				try await gateway.broadcast(ping: ping, forUser: userID)
			case let .honk(honk):
				// TODO: Broadcast honks to online recipients (there's no ServerEvent.honk yet)
				await pushIfOffline(to: honk.to) { chatId, name in .honk(from: userID, senderName: name, chatId: chatId, lastActiveInChat: now) }
			case let .chatMessage(message):
				try await chatService.saveMessage(message.message, from: userID, to: message.to, at: now)
				await gateway.send(.chatMessage(.init(from: message, by: userID)), to: message.to)

				if await gateway.shouldNotifyOfMessage(message, from: userID) {
					await pushIfOffline(to: message.to) { chatId, name in .typing(from: userID, senderName: name, chatId: chatId, lastActiveInChat: now) }
				}
			case let .screenshot(screenshot):
				await gateway.send(.screenshot(from: userID), to: screenshot.to)
			case let .chatReaction(reaction):
				await gateway.send(.chatReaction(.init(from: reaction, by: userID)), to: reaction.to)
				await pushIfOffline(to: reaction.to) { chatId, name in .reaction(from: userID, senderName: name, chatId: chatId, emoji: reaction.message, lastActiveInChat: now) }
			case let .chatAudioState(audioState):
				guard let conversationID = try await database.read({ db in
					try Conversation.between(userID, and: audioState.to).select(\.id).fetchOne(db)
				}) else { return }

				try await gateway.run { try chatService.sendUpdate(for: conversationID, to: audioState.to, friendAudioState: audioState.state, gateway: $0) }
			case let .chatAsset(chatAsset):
				try await chatService.saveAsset(chatAsset, from: userID)
				await gateway.send(.chatAsset(.init(from: chatAsset, by: userID)), to: chatAsset.to)

				if chatAsset.shouldPersist == true, let kind = Asset.Kind(rawValue: chatAsset.data.assetType) {
					await pushIfOffline(to: chatAsset.to) { chatId, name in .asset(from: userID, senderName: name, chatId: chatId, kind: kind, lastActiveInChat: now) }
				}
		}
	}

	private func pushIfOffline(to recipient: User.ID, _ build: (_ chatId: Conversation.ID, _ senderName: String) -> PushNotification) async {
		guard await gateway.isOnline(userID: recipient) == false else { return }

		do {
			guard let (chatId, nickname, senderName) = try await database.read({ db in
				try Conversation.between(userID, and: recipient)
					.join(ConversationMember.all) { $1.id.conversationId.eq($0.id) && $1.id.userId.eq(recipient) }
					.join(User.all) { $2.id.eq(userID) }
					.select { ($0.id, $1.nickname, $2.name) }
					.fetchOne(db)
			}) else { return }

			try await apns.send(build(chatId, nickname ?? senderName), to: recipient)
		} catch {
			Self.logger.error("Failed to push notification: \(error)", error: error)
		}
	}
}
