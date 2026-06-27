import SQLiteData
import Hummingbird
import Dependencies
import HummingbirdRouter

struct ContactsController: RouterController {
	var body: some RouterMiddleware<Context> {
		Post("contacts", handler: linkContacts)

		RouteGroup("contacts", context: AuthContext.self) {
			Get("onHonk", handler: findHonkContacts)
			Get("notOnHonk", handler: findNotOnHonkContacts)
		}
	}

	@Dependency(\.defaultDatabase) var database

	func linkContacts(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
		let authToken = try context.requireAuthToken()
		let request = try await request.decode(as: ContactsLinkRequest.self, context: context)

		try await database.write { db in
			try ContactHash.upsert {
				request.contacts.map { ContactHash(userFirebaseUid: authToken.sub.value, hash: $0) }
			}
			.execute(db)
		}

		return .ok
	}

	func findHonkContacts(_: Request, context: AuthContext) async throws -> FriendsOnHonkResponse {
		let me = context.user

		let users = try await database.read { db in
			let friendPairs: [(User.ID, User.ID)] = try Friendship
				.where { $0.state.eq("accepted") && ($0.userLowId.eq(me.id) || $0.userHighId.eq(me.id)) }
				.select { ($0.userLowId, $0.userHighId) }
				.fetchAll(db)

			let rows = try User
				.where { user in
					user.firebaseUid.neq(me.firebaseUid)
						&& ContactHash.where { $0.id.userFirebaseUid.eq(me.firebaseUid) &&
							$0.id.hash.is(user.contactHash)
						}
						.exists()
				}
				.selectAsFriendInfo(viewedBy: me, friendIds: friendPairs.map { $0.0 == me.id ? $0.1 : $0.0 })
				.fetchAll(db)

			let complimentRows = try Compliment
				.where { $0.toUserId.in(rows.map(\.0.id)) }
				.group { ($0.toUserId, $0.complimentId) }
				.select { ($0.toUserId, $0.complimentId, $0.count()) }
				.fetchAll(db)

			var compliments: [User.ID: [String: Int]] = [:]
			for (userId, complimentId, count) in complimentRows {
				compliments[userId, default: [:]][complimentId] = count
			}

			return rows.map { user, context in
				APIFriendInfo(from: user, with: context, compliments: compliments[user.id] ?? [:])
			}
		}

		return FriendsOnHonkResponse(users: users)
	}

	func findNotOnHonkContacts(_: Request, context: AuthContext) async throws -> APIContactsResponse {
		let me = context.user

		let contacts = try await database.read { db in
			enum FriendUpload: AliasName {}

			let friendUids = Friendship
				.where { $0.state.eq("accepted") }
				.join(User.all) { friendship, user in
					(friendship.userLowId.eq(me.id) && user.id.eq(friendship.userHighId))
						|| (friendship.userHighId.eq(me.id) && user.id.eq(friendship.userLowId))
				}
				.select { $1.firebaseUid }

			return try ContactHash
				.where { $0.id.userFirebaseUid.eq(me.firebaseUid) }
				.where { contact in
					!User.where { contact.id.hash.is($0.contactHash) }.exists()
				}
				.group(by: \.id.hash)
				.leftJoin(ContactHash.as(FriendUpload.self).all) { $1.id.hash.is($0.id.hash) && $1.id.userFirebaseUid.in(friendUids) }
				.select { APIContactsResponse.DecoratedContact.Columns(contact: $0.id.hash, friendCount: $1.id.userFirebaseUid.count(distinct: true)) }
				.fetchAll(db)
		}

		return APIContactsResponse(contacts: contacts)
	}
}
