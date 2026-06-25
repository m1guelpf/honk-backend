import SQLiteData
import Foundation
import Hummingbird
import Dependencies
import HummingbirdRouter

struct DevicesController: RouterController {
	var body: some RouterMiddleware<AuthContext> {
		Post("notifications/registerDevice", handler: register)
		Delete("notifications/device", handler: delete)
	}

	func register(_ request: Request, context: AuthContext) async throws -> RegisterDeviceResponse {
		@Dependency(\.date.now) var now
		@Dependency(\.defaultDatabase) var database

		let request = try await request.decode(as: RegisterDeviceRequest.self, context: context)

		guard let device = try await database.write({ db in
			try Device.insert {
				Device(
					id: Device.ID(deviceId: request.deviceId, userId: context.user.id),
					apnsToken: request.notificationToken,
					voipToken: request.voipToken,
					platform: "ios",
					appVersion: "1.7.3",
					sandbox: request.sandbox,
					createdAt: now,
					updatedAt: now
				)
			} onConflictDoUpdate: { device, _ in
				device.updatedAt = now
				device.sandbox = request.sandbox

				if let apnsToken = request.notificationToken {
					device.apnsToken = #bind(apnsToken)
				}

				if let voipToken = request.voipToken {
					device.voipToken = #bind(voipToken)
				}
			}
			.returning(\.self)
			.fetchOne(db)
		}) else { throw HTTPError(.internalServerError, message: "Failed to register device") }

		// TODO: Figure out what the `unregisterToken` is used for.
		return RegisterDeviceResponse(unregisterToken: device.id.deviceId)
	}

	func delete(_ request: Request, context: AuthContext) async throws -> HTTPResponse.Status {
		@Dependency(\.date.now) var now
		@Dependency(\.defaultDatabase) var database

		let request = try await request.decode(as: UnregisterDeviceRequest.self, context: context)

		try await database.write { db in
			try Device.where {
				$0.id.userId.eq(context.user.id) && ($0.id.deviceId.eq(request.unregisterToken) || $0.apnsToken.eq(request.unregisterToken) || $0.voipToken.eq(request.unregisterToken))
			}
			.delete()
			.execute(db)
		}

		return .ok
	}
}
