import Foundation
import SQLiteData
import Hummingbird
import Dependencies
import HummingbirdRouter

struct FriendsController: RouterController {
	var body: some RouterMiddleware<AuthContext> {
		RouteGroup("/friends") {
			Get("paginated", handler: getFriends)
			Get("updates", handler: getFriendUpdates)
			Get("suggested", handler: getSuggestedFriends)
			Get("lastActive", handler: getRecentlyActiveFriends)
			Post(":userId/accept", handler: acceptFriendRequest)
			Post(":userId/decline", handler: declineFriendRequest)
			Post(":userId", handler: friendshipRequest)
		}
	}

	@Dependency(\.date.now) var now
	@Dependency(\.gateway) var gateway
	@Dependency(\.defaultDatabase) var database

	func getFriends(_ request: Request, context: AuthContext) async throws -> FriendsPaginatedResponse {
		let me = context.user
		let query = try request.uri.decodeQuery(as: PaginationQuery.self, context: context)

		let (allFriendshipIds, pageRows, complimentsByUser) = try await database.read { db in
			let allFriendshipIds = try Friendship
				.where { $0.involves(me.id) && $0.state.neq(Friendship.State.declined) }
				.order(by: \.id)
				.select(\.id)
				.fetchAll(db)

			let pageRows = try Friendship
				.where { $0.involves(me.id) && $0.state.neq(Friendship.State.declined) }
				.limit(query.limit, offset: query.offset)
				.join(Conversation.all) { $0.id.eq($1.friendshipId) }
				.order { ($1.lastActivityAt.desc(), $0.id) }
				.join(ConversationMember.all) { _, conversation, member in
					member.id.conversationId.is(conversation.id) && member.id.userId.eq(me.id)
				}
				.join(User.all) { friendship, _, _, user in
					user.id.eq(friendship.friendId(besides: me.id))
				}
				.select { friendship, conversation, member, user in
					FriendPageRow.Columns(user: user, friendship: friendship, conversation: conversation, member: member, context: user.asFriendContext(viewedBy: me))
				}
				.fetchAll(db)

			let complimentsByUser = try Compliment.counts(for: pageRows.map { $0.friendship.friendId(besides: me.id) }, in: db)

			return (allFriendshipIds, pageRows, complimentsByUser)
		}

		let isUserOnline = await gateway.areOnline(userIDs: pageRows.map(\.user.id))

		let friends = pageRows.map { row -> APIFriendItem in
			let friend = APIFriendInfo(from: row.user, with: row.context, compliments: complimentsByUser[row.user.id] ?? [:], isOnline: isUserOnline[row.user.id] ?? false)

			return APIFriendItem(
				requestMessage: row.friendship.requestMessage,
				friendship: APIFriendshipInfo(from: row.friendship, with: .init(conversation: row.conversation, state: .init(from: row.friendship))),
				chat: APIChatInfo(from: row.conversation, with: .init(friend: friend, member: row.member)),
				friend: friend
			)
		}

		return FriendsPaginatedResponse(friends: friends, allFriendships: allFriendshipIds)
	}

	func getFriendUpdates(_ request: Request, context: AuthContext) async throws -> FriendUpdatesResponse {
		let me = context.user
		let query = try request.uri.decodeQuery(as: FriendUpdatesQuery.self, context: context)

		let (allFriendshipIds, changedRows, complimentsByUser) = try await database.read { db in
			let allFriendshipIds = try Friendship
				.where { $0.involves(me.id) && $0.state.neq(Friendship.State.declined) }
				.order(by: \.id)
				.select { ($0.id, $0.isDiscover) }
				.fetchAll(db)

			let changedRows = try Friendship
				.where { $0.involves(me.id) && $0.state.neq(Friendship.State.declined) }
				.join(Conversation.all) { $0.id.eq($1.friendshipId) }
				.join(ConversationMember.all) { _, conversation, member in
					member.id.conversationId.is(conversation.id) && member.id.userId.eq(me.id)
				}
				.join(User.all) { friendship, _, _, user in
					user.id.eq(friendship.friendId(besides: me.id))
				}
				.where { friendship, conversation, _, user in
					friendship.updatedAt.gt(query.lastCollected) || user.updatedAt.gt(query.lastCollected) || conversation.updatedAt.gt(query.lastCollected)
				}
				.select { friendship, conversation, member, user in
					FriendPageRow.Columns(user: user, friendship: friendship, conversation: conversation, member: member, context: user.asFriendContext(viewedBy: me))
				}
				.fetchAll(db)

			let complimentsByUser = try Compliment.counts(for: changedRows.map { $0.friendship.friendId(besides: me.id) }, in: db)

			return (allFriendshipIds, changedRows, complimentsByUser)
		}

		let isUserOnline = await gateway.areOnline(userIDs: changedRows.map(\.user.id))

		var chatUpdates: [APIChatInfo] = []
		var newFriends: [APIFriendItem] = []
		var friendUpdates: [APIFriendInfo] = []
		var friendshipUpdates: [APIFriendshipInfo] = []

		for row in changedRows {
			let friend = APIFriendInfo(from: row.user, with: row.context, compliments: complimentsByUser[row.user.id] ?? [:], isOnline: isUserOnline[row.user.id] ?? false)
			let chat = APIChatInfo(from: row.conversation, with: .init(friend: friend, member: row.member))
			let friendship = APIFriendshipInfo(from: row.friendship, with: .init(conversation: row.conversation, state: .init(from: row.friendship)))

			guard row.friendship.createdAt <= query.lastCollected else {
				newFriends.append(APIFriendItem(requestMessage: row.friendship.requestMessage, friendship: friendship, chat: chat, friend: friend))
				continue
			}

			if row.user.updatedAt > query.lastCollected { friendUpdates.append(friend) }
			if row.conversation.updatedAt > query.lastCollected { chatUpdates.append(chat) }
			if row.friendship.updatedAt > query.lastCollected { friendshipUpdates.append(friendship) }
		}

		return FriendUpdatesResponse(
			updates: .init(chatUpdates: chatUpdates, friendUpdates: friendUpdates, friendshipUpdates: friendshipUpdates),
			allFriendships: allFriendshipIds.filter { !$0.1 }.map(\.0),
			newFriends: newFriends,
			allDiscoverFriendships: allFriendshipIds.filter { $0.1 }.map(\.0)
		)
	}

	func getSuggestedFriends(_: Request, context: AuthContext) async throws -> SuggestedFriendsResponse {
		let me = context.user

		let (ranked, compliments) = try await database.read { db in
			let myFriendIds = Friendship
				.where { $0.state.eq(Friendship.State.accepted) && $0.involves(me.id) }
				.select { $0.friendId(besides: me.id) }

			let ranked = try User
				.where { user in
					user.id.neq(me.id) && user.showInSuggested &&
						!Block.where { $0.isBetween(me.id, and: user.id) }.exists() &&
						!Friendship.where { $0.involves(me.id) && $0.involves(user.id) && $0.state.neq(Friendship.State.declined) }.exists() &&
						Friendship.where { $0.state.eq(Friendship.State.accepted) && $0.involves(user.id) && $0.friendId(besides: user.id).in(myFriendIds) }.exists()
				}
				.order { user in
					Friendship.where {
						$0.state.eq(Friendship.State.accepted)
							&& $0.involves(user.id)
							&& $0.friendId(besides: user.id).in(myFriendIds)
					}
					.count()
					.desc()
				}
				.limit(50)
				.selectAsFriendInfo(viewedBy: me)
				.fetchAll(db)

			return try (ranked, Compliment.counts(for: ranked.map(\.0.id), in: db))
		}

		let isUserOnline = await gateway.areOnline(userIDs: ranked.map(\.0.id))

		return SuggestedFriendsResponse(suggested: ranked.map { user, context in
			APIFriendInfo(from: user, with: context, compliments: compliments[user.id] ?? [:], isOnline: isUserOnline[user.id] ?? false)
		})
	}

	func getRecentlyActiveFriends(_ request: Request, context: AuthContext) async throws -> RecentlyActiveFriendsResponse {
		let query = try request.uri.decodeQuery(as: RecentlyActiveQuery.self, context: context)
		let me = context.user

		let lastActive = try await database.read { db in
			let myFriendIds = Friendship
				.where { $0.state.eq(Friendship.State.accepted) && $0.involves(me.id) }
				.select { $0.friendId(besides: me.id) }

			return try User
				.where { $0.id.in(myFriendIds) }
				.order { $0.lastOnlineAt.desc() }
				.limit(query.amountOfFriends)
				.select {
					RecentlyActiveFriendsResponse.RecentlyActiveFriend.Columns(firebaseAuthId: $0.id, lastOnlineAt: $0.lastOnlineAt)
				}
				.fetchAll(db)
		}

		return RecentlyActiveFriendsResponse(lastActive: lastActive)
	}

	func friendshipRequest(_: Request, context: AuthContext) async throws -> APIFriendshipInfo {
		guard let userId = context.parameters.get("userId") else { throw HTTPError(.badRequest) }
		guard context.user.id != userId else { throw HTTPError(.forbidden, message: "You can not follow yourself.") }

		let me = context.user
		let (lowId, highId) = me.id < userId ? (me.id, userId) : (userId, me.id)

		// TODO: figure out what to do about (userLowId, userHighId) uniqueness constraint here
		let friendship = Friendship(
			id: objectID(),
			userLowId: lowId,
			userHighId: highId,
			state: .pending,
			creator: me.id,
			isTemporary: false, // TODO: How do we know?
			isDiscover: false, // TODO: How do we know?
			isFromTopPick: false, // TODO: Fill this later
			currentStreakCount: 0,
			bestStreakCount: 0,
			likelyOffensive: false, // TODO: where does this come from?
			createdAt: now,
			updatedAt: now
		)

		try await database.write { db in
			guard let blocked = try Values(Block.where { $0.isFrom(userId, to: me.id) }.exists()).fetchOne(db), !blocked
			else { throw HTTPError(.forbidden, message: "You can't send this user a friend request.") }

			guard let allowsFriendRequests = try User.find(userId).select(\.allowFriendRequests).fetchOne(db), allowsFriendRequests
			else { throw HTTPError(.forbidden, message: "You can't send this user a friend request.") }

			try Friendship.insert { friendship }.execute(db)
		}

		return APIFriendshipInfo(from: friendship, with: .init(conversation: nil, state: .init(from: friendship)))
	}

	func acceptFriendRequest(_: Request, context: AuthContext) async throws -> APIFriendshipInfo {
		guard let userId = context.parameters.get("userId") else { throw HTTPError(.badRequest) }
		let me = context.user

		guard let friendship = try await database.write({ db in
			try Friendship
				.where { $0.involves(me.id) && $0.involves(userId) && $0.state.eq(Friendship.State.pending) && $0.creator.neq(me.id) }
				.update {
					$0.updatedAt = #bind(now)
					$0.state = #bind(.accepted)
				}
				.returning(\.self)
				.fetchOne(db)
		}) else { throw HTTPError(.notFound, message: "No pending friend request from this user.") }

		return APIFriendshipInfo(from: friendship, with: .init(conversation: nil, state: .init(from: friendship)))
	}

	func declineFriendRequest(_: Request, context: AuthContext) async throws -> APIFriendshipInfo {
		guard let userId = context.parameters.get("userId") else { throw HTTPError(.badRequest) }
		let me = context.user

		guard let friendship = try await database.write({ db in
			try Friendship
				.where { $0.involves(me.id) && $0.involves(userId) && $0.state.eq(Friendship.State.pending) && $0.creator.neq(me.id) }
				.update {
					$0.updatedAt = #bind(now)
					$0.state = #bind(.declined)
				}
				.returning(\.self)
				.fetchOne(db)
		}) else { throw HTTPError(.notFound, message: "No pending friend request from this user.") }

		return APIFriendshipInfo(from: friendship, with: .init(conversation: nil, state: .init(from: friendship)))
	}
}

// MARK: - Database Queries

@Selection struct FriendPageRow {
	let user: User
	let friendship: Friendship
	let conversation: Conversation
	let member: ConversationMember
	let context: APIFriendInfo.Context
}
