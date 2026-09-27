import Foundation
import SQLiteData
import Hummingbird
import Dependencies
import HummingbirdRouter

struct CallsController: RouterController {
	var body: some RouterMiddleware<AuthContext> {
		RouteGroup("chat/call") {
			Post(":friendshipId", handler: start)
			Post(":callId/accept", handler: accept)
			Post(":callId/decline", handler: decline)
		}
	}

	@Dependency(\.apns) var apns
	@Dependency(\.agora) var agora
	@Dependency(\.date.now) var now
	@Dependency(\.gateway) var gateway
	@Dependency(\.defaultDatabase) var database

	func start(_ request: Request, context: AuthContext) async throws -> CallResponse {
		guard let friendshipID = context.parameters.get("friendshipId") else { throw HTTPError(.badRequest) }
		let body = try await request.decode(as: StartCallRequest.self, context: context)
		let me = context.user

		let (call, created) = try await database.write { db in
			let friendship = try friendship(friendshipID, for: me.id, in: db)

			let calls = try Call.where {
				$0.id.eq(body.callId) || ($0.state.neq(Call.State.declined) && ($0.involves(me.id) || $0.involves(friendship.friendId(besides: me.id))))
			}
			.fetchAll(db)

			if let call = calls.first(where: { $0.id == body.callId }) {
				guard call.callerId == me.id, call.friendshipId == friendshipID, call.state != .declined else {
					throw HTTPError(.conflict, message: "This call has ended or belongs to another user.")
				}

				return (call, false)
			}

			guard calls.isEmpty else { throw HTTPError(.conflict, message: "A user is already on a call.") }

			let call = Call(
				id: body.callId,
				friendshipId: friendshipID,
				callerId: me.id,
				recipientId: friendship.friendId(besides: me.id),
				state: .requested,
				expiresAt: now.adding(.minutes(1)),
				createdAt: now,
				updatedAt: now
			)

			try Call.insert { call }.execute(db)

			return (call, true)
		}

		let key = try agora.token(for: call.id, expiresAt: call.tokenExpiry)

		if created {
			let shouldPush = await gateway.run { gateway in
				gateway.send(.callRequested(.init(call: APICall(from: call, viewedBy: call.recipientId), friendshipId: call.friendshipId, userId: me.id)), to: call.recipientId)

				guard gateway.isOnline(userID: call.recipientId), let presence = gateway.presence(userID: call.recipientId) else { return true }
				return !presence.isOnline || !presence.appIsActive
			}

			if shouldPush {
				do { try await apns.send(.calling(from: me.id, callId: call.id, friendshipId: call.friendshipId), to: call.recipientId) }
				catch { context.logger.error("Failed to send call notification: \(error)") }
			}
		}

		return CallResponse(channelName: call.id, key: key, call: APICall(from: call, viewedBy: me.id))
	}

	func accept(_: Request, context: AuthContext) async throws -> AcceptCallResponse {
		guard let callID = context.parameters.get("callId", as: UUID.self) else { throw HTTPError(.badRequest) }
		let me = context.user

		let (call, changed) = try await database.write { db in
			guard var call = try Call.find(callID).where({ $0.recipientId.eq(me.id) }).fetchOne(db) else { throw HTTPError(.notFound) }
			guard call.state != .declined else { throw HTTPError(.conflict, message: "This call has ended.") }
			try friendship(call.friendshipId, for: me.id, in: db)
			guard call.state == .requested else { return (call, false) }

			try Call.find(callID)
				.update {
					$0.updatedAt = now
					$0.state = #bind(.accepted)
					$0.expiresAt = call.tokenExpiry
				}
				.execute(db)

			return (call, true)
		}

		if changed {
			await gateway.send(.userJoinedCall(callId: call.id, userId: me.id, friendshipId: call.friendshipId), to: call.callerId)
		}

		return try AcceptCallResponse(channelName: call.id, key: agora.token(for: call.id, expiresAt: call.tokenExpiry))
	}

	func decline(_: Request, context: AuthContext) async throws -> MessageResponse {
		guard let callID = context.parameters.get("callId", as: UUID.self) else { throw HTTPError(.badRequest) }
		let me = context.user

		let call = try await database.write { db -> Call? in
			guard var call = try Call.find(callID).where({ $0.involves(me.id) }).fetchOne(db) else { throw HTTPError(.notFound) }
			guard call.state != .declined else { return nil }

			try Call.find(callID)
				.update {
					$0.updatedAt = now
					$0.state = #bind(.declined)
				}
				.execute(db)

			return call
		}

		if let call {
			await gateway.run { gateway in
				for recipient in [call.callerId, call.recipientId] {
					gateway.send(.userDeclined(callId: call.id, userId: me.id), to: recipient)
				}
			}
		}

		return MessageResponse(message: "Call ended.")
	}

	@discardableResult
	private func friendship(_ id: Friendship.ID, for userID: User.ID, in db: Database) throws -> Friendship {
		let friendship = try Friendship.find(id)
			.where { friendship in
				friendship.involves(userID) && friendship.state.eq(Friendship.State.accepted) && !Block.where { $0.isBetween(friendship.userLowId, and: friendship.userHighId) }.exists()
			}
			.fetchOne(db)

		guard let friendship else { throw HTTPError(.notFound) }
		return friendship
	}
}
