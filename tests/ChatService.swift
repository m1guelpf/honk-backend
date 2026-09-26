import Testing
import CustomDump
import Foundation
import SQLiteData
@testable import HonkBackend
import Dependencies
import HummingbirdTesting
import DependenciesTestSupport

extension Tests {
	@Suite(.dependencies { try $0.bootstrapDatabase() })
	struct ChatServiceTests {
		@Dependency(\.uuid) var uuid
		@Dependency(\.date.now) var now
		@Dependency(\.gateway) var gateway
		@Dependency(\.chatService) var chatService
		@Dependency(\.defaultDatabase) var database

		init() throws {
			try database.write { db in
				try User.insert {
					for id in ["sender", "recipient"] {
						User(id: id, username: id, name: id, avatarUrl: URL(string: "https://example.com/avatar")!, birthday: now, lastOnlineAt: now, createdAt: now, updatedAt: now)
					}
				}
				.execute(db)

				try Friendship.insert {
					Friendship(
						id: "friendship", userLowId: "recipient", userHighId: "sender", state: .accepted, creator: "sender",
						isTemporary: false, isDiscover: false, isFromTopPick: false, currentStreakCount: 0,
						bestStreakCount: 0, likelyOffensive: false, createdAt: now, updatedAt: now
					)
				}
				.execute(db)
			}
		}

		@Test func offlineMessageIsUnreadOnlyForRecipient() async throws {
			try await chatService.saveMessage("Hello", from: "sender", to: "recipient", at: now)

			#expect(try member().hasUnread)
			#expect(try !member("sender").hasUnread)

			let message = try await database.read { try Message.fetchOne($0) }
			expectNoDifference(message?.text, "Hello")
		}

		@Test(arguments: [
			APIPresence(ping_id: 1, isOnline: true, appIsActive: true),
			APIPresence(ping_id: 1, isOnline: true, appIsActive: false, isInChat: "friendship"),
			APIPresence(ping_id: 1, isOnline: false, appIsActive: true, isInChat: "friendship"),
			APIPresence(ping_id: 1, isOnline: true, appIsActive: true, isInChat: "different-chat"),
		]) func presenceOutsideActiveChatDoesNotReadMessages(_ ping: APIPresence) async throws {
			try await gateway.test(actingAs: "recipient") { gateway in
				try gateway.broadcast(ping: ping, forUser: "recipient")
				try await chatService.saveMessage("Hello", from: "sender", to: "recipient", at: now)
				#expect(try member().hasUnread)
				try gateway.broadcast(ping: ping, forUser: "recipient")
				#expect(try member().hasUnread)
			}
		}

		@Test func openingChatClearsUnread() async throws {
			let events = try await gateway.test(actingAs: "recipient") { gateway in
				try await chatService.saveMessage("Hi", from: "sender", to: "recipient", at: now)
				#expect(try member().hasUnread)

				try gateway.broadcast(ping: activePresence, forUser: "recipient")
				#expect(try !member().hasUnread)
				try expectNoDifference(member().lastReadAt, now)
			}

			var unreadUpdates: [Bool] = []
			for await event in events {
				if case let .chatUpdate(update) = event {
					unreadUpdates.append(update.data.unreadNotifications)
					expectNoDifference(update.data.userId, "recipient")
					try expectNoDifference(update.key, member().id.conversationId)
				}
			}
			expectNoDifference(unreadUpdates, [true, false])
		}

		@Test func viewingChatKeepsNewContentRead() async throws {
			try await gateway.test(actingAs: "recipient") { gateway in
				try gateway.broadcast(ping: activePresence, forUser: "recipient")
				try await chatService.saveMessage("Hello", from: "sender", to: "recipient", at: now)
				try await chatService.saveAsset(asset(), from: "sender")
				#expect(try !member().hasUnread)
			}
		}

		@Test func emptyTextDoesNotCreateOrClearUnread() async throws {
			try await chatService.saveMessage("", from: "sender", to: "recipient", at: now)
			#expect(try !member().hasUnread)
			try await chatService.saveMessage("Hello", from: "sender", to: "recipient", at: now)
			try await chatService.saveMessage("", from: "sender", to: "recipient", at: now)
			#expect(try member().hasUnread)
		}

		@Test func onlyPersistedAssetsCreateUnread() async throws {
			var event = asset()
			event.shouldPersist = false
			try await chatService.saveAsset(event, from: "sender")
			#expect(try !member().hasUnread)
			let assetCount = try await database.read { try Asset.fetchCount($0) }
			expectNoDifference(assetCount, 0)

			event.shouldPersist = true
			try await chatService.saveAsset(event, from: "sender")
			#expect(try member().hasUnread)
			let assetID = try await database.read { try ConversationAsset.fetchOne($0)?.assetId }
			expectNoDifference(assetID, event.data.contentID.uuidString)
		}

		@Test func unreadFailureRollsBackTheMessage() async throws {
			try await database.write { db in
				try ConversationMember.createTemporaryTrigger(before: .update(of: \.hasUnread) { _, _ in
					#sql("SELECT RAISE(ABORT, 'Unread update failed')")
				} when: { _, new in new.hasUnread })
					.execute(db)
			}
			await #expect(throws: (any Error).self) {
				try await chatService.saveMessage("Hello", from: "sender", to: "recipient", at: now)
			}
			let messageCount = try await database.read { try Message.fetchCount($0) }
			expectNoDifference(messageCount, 0)
			#expect(try !member().hasUnread)
		}

		@Test func httpSaveUpdatesUnreadInChatResponse() async throws {
			try await configure().test(.router) { client in
				try await client.post("/chat/recipient", actingAs: "sender", body: SendMessageRequest(type: .text, message: "Hello", isTemporary: false, date: now)) { response in
					expectNoDifference(response.status, .ok)
				}

				try await client.get("/chat/sender/friendship", actingAs: "recipient") { response in
					expectNoDifference(response.status, .ok)
					let body = try response.decode(as: ChatFriendshipResponse.self)
					#expect(body.chat.unreadNotifications)
				}
			}
		}

		private var activePresence: APIPresence {
			APIPresence(ping_id: 1, isOnline: true, appIsActive: true, isInChat: "friendship")
		}

		private func member(_ userID: User.ID = "recipient") throws -> ConversationMember {
			try database.read { db in
				let member = try ConversationMember.where { $0.id.userId.eq(userID) }.fetchOne(db)
				return try #require(member)
			}
		}

		private func asset() -> ClientEvent.ChatAsset {
			ClientEvent.ChatAsset(to: "recipient", shouldPersist: true, isFromTemporary: false, data: .init(caption: "", assetType: "image", contentID: uuid()))
		}
	}
}
