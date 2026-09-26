import APNS
import Crypto
import Logging
import APNSCore
import NIOPosix
import Foundation
import SQLiteData
import Dependencies
import Configuration
import Synchronization
import DependenciesMacros

struct APNs: Sendable {
	enum Environment: String, Sendable, Hashable {
		case production, sandbox

		var server: APNSEnvironment {
			switch self {
				case .sandbox: .development
				case .production: .production
			}
		}
	}

	enum Outcome: String, Sendable {
		case sent, unregistered, failed
	}

	private let send: @Sendable (_ push: PushNotification, _ deviceToken: String) async throws -> Outcome

	init(send: @escaping @Sendable (PushNotification, String) async throws -> Outcome) {
		self.send = send
	}

	func send(_ push: PushNotification, to userID: User.ID) async throws {
		@Dependency(\.defaultDatabase) var database
		let devices = try await database.read { db in
			try Device.where { $0.id.userId.eq(userID) && $0.apnsToken.isNot(nil) }.fetchAll(db)
		}

		let deadTokens = try await withThrowingTaskGroup(of: (String, APNs.Outcome?).self) { group in
			var dead: [String?] = []

			for device in devices {
				guard let token = device.apnsToken else { continue }

				group.addTask { try (token, await send(push, token)) }
			}

			for try await (token, outcome) in group {
				if let outcome, case .unregistered = outcome { dead.append(token) }
			}

			return dead
		}

		guard !deadTokens.isEmpty else { return }
		try await database.write { db in
			try Device.where { $0.apnsToken.in(deadTokens) }.delete().execute(db)
		}
	}
}

// MARK: - Dependency

extension APNs: DependencyKey {
	static let logger = Logger(label: "APNs")

	static let liveValue = APNs(
		send: { push, deviceToken in
			do {
				@Dependency(\.config) var config

				let topic = try config.requiredString(forKey: "apns.topic")
				let client = try getSharedClient()

				// Silent types (badgeUpdate, userUpdate) carry no alert — they exist purely
				// to nudge the client into re-syncing, so they go out as background pushes.
				guard let alert = push.alert else {
					_ = try await client.sendBackgroundNotification(
						APNSBackgroundNotification(expiration: .immediately, topic: topic, payload: push),
						deviceToken: deviceToken
					)

					return .sent
				}

				let notification = APNSAlertNotification(
					alert: .init(title: .raw(alert.title), body: .raw(alert.body)),
					expiration: .immediately,
					priority: .immediately,
					topic: topic,
					payload: push,
					badge: alert.badge,
					sound: alert.sound.map(APNSAlertNotificationSound.fileName) ?? .default
				)

				_ = try await client.sendAlertNotification(notification, deviceToken: deviceToken)
				return .sent
			} catch let error as APNSError where error.reason == .unregistered || error.reason == .badDeviceToken {
				return .unregistered
			} catch {
				logger.error("Failed to send push notification: \(error)")
				return .failed
			}
		}
	)
}

extension DependencyValues {
	var apns: APNs {
		get { self[APNs.self] }
		set { self[APNs.self] = newValue }
	}
}

fileprivate let sharedAPNsClient = Mutex<APNSClient<JSONDecoder, JSONEncoder>?>(nil)
fileprivate func getSharedClient() throws -> APNSClient<JSONDecoder, JSONEncoder> {
	try sharedAPNsClient.withLock { box in
		if let box { return box }

		@Dependency(\.config) var config
		let privateKeyPEM = try config.requiredString(forKey: "apns.privateKey", isSecret: true)
			.replacingOccurrences(of: "\\n", with: "\n")
		let client = try APNSClient(
			configuration: APNSClientConfiguration(
				authenticationMethod: .jwt(
					privateKey: .init(pemRepresentation: privateKeyPEM),
					keyIdentifier: config.requiredString(forKey: "apns.keyId", isSecret: true),
					teamIdentifier: config.requiredString(forKey: "apns.teamId", isSecret: true)
				),
				environment: config.requiredString(forKey: "apns.environment", as: APNs.Environment.self).server
			),
			eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup.singleton),
			responseDecoder: JSONDecoder(),
			requestEncoder: JSONEncoder()
		)

		box = client
		return client
	}
}
