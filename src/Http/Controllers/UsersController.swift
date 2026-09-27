import Foundation
import SQLiteData
import Hummingbird
import Dependencies
import HummingbirdRouter

struct UsersController: RouterController {
	var body: some RouterMiddleware<AuthContext> {
		Get("users/blocked", handler: blockedUsers)
		Get("users/:userId", handler: getUser)
		Put("users/:userId", handler: updateUser)
		Delete("users/:userId", handler: deleteUser)
	}

	@Dependency(\.date.now) var now
	@Dependency(\.gateway) var gateway
	@Dependency(\.defaultDatabase) var database

	func blockedUsers(_: Request, context: AuthContext) async throws -> [String] {
		return try await database.read { db in
			try Block.where { $0.id.blockerId.eq(context.user.id) }.select { $0.id.blockedId }.fetchAll(db)
		}
	}

	func getUser(_: Request, context: AuthContext) throws -> UserResponse {
		guard let userId = context.parameters.get("userId") else { throw HTTPError(.badRequest) }
		guard context.user.id == userId else { throw HTTPError(.forbidden, message: "You can only fetch your own user data.") }

		// TODO: Fetch compliments for the user?
		return UserResponse(user: APIUserInfo(context.user, compliments: [:], shouldForceReloadFriends: false))
	}

	func updateUser(_ request: Request, context: AuthContext) async throws -> UserResponse {
		guard let userId = context.parameters.get("userId") else { throw HTTPError(.badRequest) }
		guard context.user.id == userId else { throw HTTPError(.forbidden, message: "You can only fetch your own user data.") }

		let patch = try await request.decode(as: AccountUpdateRequest.self, context: context)

		let (user, recipients, compliments) = try await database.write { db in
			guard let user = try User.find(context.user.id).update(apply: patch).returning(\.self).fetchOne(db)
			else { throw HTTPError(.internalServerError, message: "Failed to update user.") }

			let recipients = try Friendship
				.where { $0.involves(user.id) && $0.state.neq(Friendship.State.declined) }
				.join(Conversation.all) { $0.id.eq($1.friendshipId) }
				.join(ConversationMember.all) { _, conversation, member in
					member.id.conversationId.eq(conversation.id) && member.id.userId.neq(user.id)
				}
				.join(User.all) { _, _, _, profile in profile.id.eq(user.id) }
				.select { _, _, member, profile in
					(member.id.userId, profile.asFriendContext(viewedBy: member.id.userId))
				}
				.fetchAll(db)

			return try (user, recipients, Compliment.counts(for: [user.id], in: db)[user.id] ?? [:])
		}

		await gateway.run { gateway in
			for (recipient, context) in recipients {
				let friend = APIFriendInfo(from: user, with: context, compliments: compliments, isOnline: gateway.isOnline(userID: user.id))
				gateway.send(.friendUpdate(.init(key: user.id, data: friend)), to: recipient)
			}
		}

		return UserResponse(user: APIUserInfo(user, compliments: compliments, shouldForceReloadFriends: false))
	}

	func deleteUser(_: Request, context: AuthContext) async throws -> MessageResponse {
		guard let userId = context.parameters.get("userId") else { throw HTTPError(.badRequest) }
		guard context.user.id == userId else { throw HTTPError(.forbidden, message: "You can only delete your own account.") }

		try await database.write { db in
			try User.find(context.user.id).delete().execute(db)
		}

		return MessageResponse(message: "Account Deleted")
	}
}
