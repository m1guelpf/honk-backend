import Testing
import CustomDump
import Foundation
import SQLiteData
@testable import HonkBackend
import Dependencies
import Synchronization
import DependenciesTestSupport

extension Tests {
	@Suite(.dependencies { try $0.bootstrapDatabase() })
	struct ConnectionTests {
		@Dependency(\.date.now) var now
		@Dependency(\.defaultDatabase) var database

		let sender = "connection-sender"
		let recipient = "connection-recipient"

		init() throws {
			try database.write { db in
				try User.insert {
					User(id: sender, username: sender, name: "Alice", avatarUrl: URL(string: "https://example.com/alice")!, birthday: now, honkButton: .fruit, lastOnlineAt: now, createdAt: now, updatedAt: now)
					User(id: recipient, username: recipient, name: "Bob", avatarUrl: URL(string: "https://example.com/bob")!, birthday: now, honkButton: .music, lastOnlineAt: now, createdAt: now, updatedAt: now)
				}
				.execute(db)

				try Friendship.insert {
					Friendship(
						id: "connection-friendship", userLowId: recipient, userHighId: sender, state: .accepted, creator: sender,
						isTemporary: false, isDiscover: false, isFromTopPick: false, currentStreakCount: 0,
						bestStreakCount: 0, likelyOffensive: false, createdAt: now, updatedAt: now
					)
				}
				.execute(db)

				try ConversationMember.where { $0.id.userId.eq(sender) }
					.update { $0.nickname = #bind("Bobby") }
					.execute(db)
			}
		}

		@Test(arguments: ["recording", nil] as [String?])
		func audioStateUsesRecipientChatSettings(_ state: String?) async throws {
			let chatID = try await database.write { db in
				try ConversationMember.where { $0.id.userId.eq(recipient) }
					.update {
						$0.nickname = #bind("Ally")
						$0.hasUnread = true
						$0.notificationsEnabled = false
						$0.muteValue = #bind(ConversationMember.MutedFor.oneHour)
						$0.honkButton = #bind(User.HonkButtonCategory.space)
					}
					.execute(db)
				return try #require(try Conversation.select(\.id).fetchOne(db))
			}

			try await Connection(userID: recipient).test { events, _ in
				try await Connection(userID: sender).test { _, send in
					try await send(.chatAudioState(.init(to: recipient, state: state)))

					var events = events.makeAsyncIterator()
					let received = try #require(await events.next())
					expectNoDifference(received, .chatUpdate(.init(key: chatID, data: APIChatInfo(
						id: chatID, chatNotifications: false, unreadNotifications: true, theme: "standard", friendAudioState: state,
						magicWords: [], muteValue: .oneHour, stats: .init(), userId: recipient, nickname: "Ally", honkButton: .space, friendHonkButton: .fruit
					))))
				}
			}
		}

		@Test(arguments: ["Ally", nil] as [String?])
		func pushUsesRecipientNicknameOrSenderName(_ nickname: String?) async throws {
			try await database.write { db in
				try ConversationMember.where { $0.id.userId.eq(recipient) }
					.update { $0.nickname = #bind(nickname) }
					.execute(db)
				try Device.insert {
					Device(id: .init(deviceId: "recipient-device", userId: recipient), apnsToken: "recipient-token", platform: "ios", sandbox: true, createdAt: now, updatedAt: now)
				}
				.execute(db)
			}

			let sentCount = Mutex(0)
			let (pushes, continuation) = AsyncStream.makeStream(of: Void.self)
			defer { continuation.finish() }
			try await withDependencies {
				$0.apns = APNs { push, token in
					expectNoDifference(push.alert?.title, nickname ?? "Alice")
					expectNoDifference(token, "recipient-token")
					sentCount.withLock { $0 += 1 }
					continuation.yield(())
					return .sent
				}
			} operation: {
				try await Connection(userID: sender).test { _, send in
					try await send(.honk(.init(to: recipient)))
					var pushes = pushes.makeAsyncIterator()
					_ = try #require(await pushes.next())
				}
			}
			expectNoDifference(sentCount.withLock { $0 }, 1)
		}
	}
}
