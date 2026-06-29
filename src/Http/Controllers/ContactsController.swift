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

	func linkContacts(_ request: Request, context: Context) async throws -> ContactsLinkResponse {
		let authToken = try context.requireAuthToken()
		let request = try await request.decode(as: ContactsLinkRequest.self, context: context)

		try await database.write { db in
			try ContactHash.upsert {
				request.contacts.map { ContactHash(userFirebaseUid: authToken.sub.value, hash: $0) }
			}
			.execute(db)
		}

		// TODO: Do we need to return any items here?
		return ContactsLinkResponse(items: [])
	}

	func findHonkContacts(_ request: Request, context: AuthContext) async throws -> FriendsOnHonkResponse {
		let me = context.user
		let query = try request.uri.decodeQuery(as: PaginationQuery.self, context: context)

		let users = try await database.read { db in
			let friendIds = try Friendship
				.where { $0.state.eq("accepted") && $0.involves(me.id) }
				.select { $0.friendId(besides: me.id) }
				.fetchAll(db)

			let rows = try User
				.where { user in
					user.firebaseUid.neq(me.firebaseUid)
						&& ContactHash.where { $0.id.userFirebaseUid.eq(me.firebaseUid) &&
							$0.id.hash.is(user.contactHash)
						}
						.exists()
				}
				.order(by: \.id)
				.limit(query.limit + 1, offset: query.offset)
				.selectAsFriendInfo(viewedBy: me, friendIds: friendIds)
				.fetchAll(db)

			let compliments = try Compliment.counts(for: rows.map(\.0.id), in: db)

			return rows.map { user, context in
				APIFriendInfo(from: user, with: context, compliments: compliments[user.id] ?? [:])
			}
		}

		return FriendsOnHonkResponse(
			users: Array(users.prefix(query.limit)),
			moreContactsAvailable: users.count > query.limit,
			lastPageRequested: query.page
		)
	}

	func findNotOnHonkContacts(_ request: Request, context: AuthContext) async throws -> ExternalContactsResponse {
		let me = context.user
		let query = try request.uri.decodeQuery(as: PaginationQuery.self, context: context)

		let contacts = try await database.read { db in
			enum FriendUpload: AliasName {}

			let friendUids = Friendship
				.where { $0.state.eq("accepted") }
				.join(User.all) { friendship, user in
					friendship.involves(me.id) && user.id.eq(friendship.friendId(besides: me.id))
				}
				.select { $1.firebaseUid }

			return try ContactHash
				.where { $0.id.userFirebaseUid.eq(me.firebaseUid) }
				.where { contact in
					!User.where { contact.id.hash.is($0.contactHash) }.exists()
				}
				.group(by: \.id.hash)
				.leftJoin(ContactHash.as(FriendUpload.self).all) { $1.id.hash.is($0.id.hash) && $1.id.userFirebaseUid.in(friendUids) }
				.order { contact, _ in contact.id.hash }
				.limit(query.limit + 1, offset: query.offset)
				.select { ExternalContactsResponse.DecoratedContact.Columns(contact: $0.id.hash, friendCount: $1.id.userFirebaseUid.count(distinct: true)) }
				.fetchAll(db)
		}

		return ExternalContactsResponse(
			contacts: Array(contacts.prefix(query.limit)),
			moreContactsAvailable: contacts.count > query.limit,
			lastPageRequested: query.page
		)
	}
}
