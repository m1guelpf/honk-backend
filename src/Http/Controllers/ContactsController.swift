import Hummingbird
import HummingbirdRouter

struct ContactsController: RouterController {
	var body: some RouterMiddleware<Context> {
		Post("contacts", handler: linkContacts)

		RouteGroup("contacts", context: AuthContext.self) {
			Get("onHonk", handler: findHonkContacts)
			Get("notOnHonk", handler: findNotOnHonkContacts)
		}
	}

	func linkContacts(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
		let authToken = try context.requireAuthToken()
		let request = try await request.decode(as: ContactsLinkRequest.self, context: context)

		// TODO: Store contact hashes in database

		return .ok
	}

	func findHonkContacts(_: Request, context _: AuthContext) -> FriendsOnHonkResponse {
		// TODO: Fill this in once we implement contact resolution.
		FriendsOnHonkResponse(users: [])
	}

	func findNotOnHonkContacts(_: Request, context _: AuthContext) -> APIContactsResponse {
		// TODO: Fill this in once we implement contact resolution.
		APIContactsResponse(contacts: [])
	}
}
