import Logging
import SQLiteData
import Dependencies
import ServiceLifecycle

struct CallService: Service {
	static let logger = Logger(label: "Calls")

	@Dependency(\.date.now) private var now
	@Dependency(\.gateway) private var gateway
	@Dependency(\.defaultDatabase) private var database

	func run() async {
		await cancelWhenGracefulShutdown {
			while !Task.isCancelled {
				do { try await expire() }
				catch { Self.logger.error("Failed to expire calls: \(error)") }
				try? await Task.sleep(for: .seconds(5))
			}
		}
	}

	private func expire() async throws {
		let calls = try await database.write { db in
			try Call.where { $0.state.neq(Call.State.declined) && $0.expiresAt.lte(now) }
				.update {
					$0.updatedAt = #bind(now)
					$0.state = Call.State.declined
				}
				.returning(\.self)
				.fetchAll(db)
		}

		guard !calls.isEmpty else { return }
		await gateway.run { gateway in
			for call in calls {
				for recipient in [call.callerId, call.recipientId] {
					gateway.send(.userDeclined(callId: call.id, userId: call.otherUser(besides: recipient)), to: recipient)
				}
			}
		}
	}
}
