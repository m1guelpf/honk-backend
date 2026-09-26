import Testing
import WSClient
import CustomDump
import Foundation
@testable import HonkBackend
import Dependencies
import HummingbirdTesting
import HummingbirdWSTesting
import DependenciesTestSupport

extension Tests {
	@Test func messageNotificationsFollowTypingBursts() async {
		@Dependency(\.gateway) var gateway
		let message = ClientEvent.ChatMessage(to: "burst-recipient", message: "Hello", isFromTemporary: false)

		for (time, expected) in [
			(0.0, true), (0.9, true), (1.3, false), (1.7, false),
			(2.1, false), (2.5, false), (3.3, false), (4.3, true),
		] {
			let shouldNotify = await withDependencies {
				$0.date = .constant(Date(timeIntervalSinceReferenceDate: time))
			} operation: {
				await gateway.shouldNotifyOfMessage(message, from: "burst-sender")
			}
			expectNoDifference(shouldNotify, expected)
		}
	}

	@Test(.dependencies { try $0.bootstrapDatabase() }, arguments: [false, true])
	func reconnectPreservesTypingBurst(disconnectAgain: Bool) async {
		@Dependency(\.uuid) var uuid
		@Dependency(\.date.now) var now
		@Dependency(\.gateway) var gateway

		let clock = TestClock()
		let sender = "reconnect-sender-\(disconnectAgain)"
		let message = ClientEvent.ChatMessage(to: "reconnect-recipient", message: "Hello", isFromTemporary: false)
		let connectionID = uuid()
		let (_, continuation) = AsyncStream.makeStream(of: ServerEvent.self)
		defer { continuation.finish() }

		await withDependencies {
			$0.continuousClock = clock
		} operation: {
			await gateway.register(userID: sender, id: connectionID, continuation: continuation)
			#expect(await gateway.shouldNotifyOfMessage(message, from: sender))
			await gateway.unregister(userID: sender, id: connectionID)

			await clock.advance(by: .milliseconds(500))
			await gateway.register(userID: sender, id: connectionID, continuation: continuation)
			await withDependencies {
				$0.date = .constant(now.addingTimeInterval(0.5))
			} operation: {
				#expect(!(await gateway.shouldNotifyOfMessage(message, from: sender)))
			}
			if disconnectAgain { await gateway.unregister(userID: sender, id: connectionID) }

			await clock.advance(by: .milliseconds(400))
			await gateway.register(userID: sender, id: connectionID, continuation: continuation)
			await withDependencies {
				$0.date = .constant(now.addingTimeInterval(0.9))
			} operation: {
				#expect(!(await gateway.shouldNotifyOfMessage(message, from: sender)))
			}

			await gateway.unregister(userID: sender, id: connectionID)
			await clock.run()
			#expect(await gateway.shouldNotifyOfMessage(message, from: sender))
		}
	}

	@Test func messageNotificationsAreSeparateForEachSenderAndRecipient() async {
		@Dependency(\.gateway) var gateway
		let message = ClientEvent.ChatMessage(to: "pair-recipient", message: "Hello", isFromTemporary: false)
		let otherMessage = ClientEvent.ChatMessage(to: "other-recipient", message: "Hello", isFromTemporary: false)

		#expect(await gateway.shouldNotifyOfMessage(message, from: "pair-sender"))
		#expect(await gateway.shouldNotifyOfMessage(otherMessage, from: "pair-sender"))
		#expect(await gateway.shouldNotifyOfMessage(message, from: "other-sender"))
		#expect(!(await gateway.shouldNotifyOfMessage(message, from: "pair-sender")))
	}

	@Test func emptyMessagesDoNotStartTypingBursts() async {
		@Dependency(\.gateway) var gateway

		for (time, text, expected) in [
			(0.0, "", false), (0.1, "H", true), (0.8, "", false),
			(1.2, "Hi", true), (1.4, "", false), (1.6, "H", false),
		] {
			let message = ClientEvent.ChatMessage(to: "empty-recipient", message: text, isFromTemporary: false)
			let shouldNotify = await withDependencies {
				$0.date = .constant(Date(timeIntervalSinceReferenceDate: time))
			} operation: {
				await gateway.shouldNotifyOfMessage(message, from: "empty-sender")
			}
			expectNoDifference(shouldNotify, expected)
		}
	}
}

// MARK: - Gateway (WebSocket) Tests

extension Tests {
	@Test(.dependencies { try $0.bootstrapDatabase() })
	func gatewayRelaysDispatch() async throws {
		@Dependency(\.gateway) var gateway

		try await Connection(userID: "user-b").test { inbound, _ in
			await gateway.send(.friendPing(.init(userId: "user-b", isOnline: true, ping_id: 3)), to: "user-b")

			var events = inbound.makeAsyncIterator()
			let event = await events.next()
			expectNoDifference(event, .friendPing(.init(userId: "user-b", isOnline: true, ping_id: 3)))
		}
	}

	/// An upgrade without a valid Bearer token is refused — auth is on the upgrade, not in-band.
	@Test func gatewayRejectsUnauthenticated() async throws {
		let app = configure()

		try await app.test(.live) { client in
			do {
				try await client.ws("/chat") { _, _, _ in }
			} catch let error as WSClient.WebSocketClientError {
				expectNoDifference(error.description, "WebSocket upgrade failed")
			} catch {
				Issue.record("expected a WSClient.WebSocketClientError, got \(error)")
			}
		}
	}
}
