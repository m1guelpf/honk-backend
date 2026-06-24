import SQLiteData
import Hummingbird
import Dependencies

public struct AuthenticateUsers: RouterMiddleware {
	@Dependency(\.authTokens) var authTokens
	@Dependency(\.defaultDatabase) var database

	public func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
		guard let authToken = try await retrieveToken(request: request) else {
			return try await next(request, context)
		}

		var context = context
		context.authToken = authToken

		guard let user = try await authenticate(authToken: authToken) else {
			return try await next(request, context)
		}

		context.user = user
		return try await next(request, context)
	}

	func retrieveToken(request: Request) async throws -> HonkAuthTokens.AuthToken? {
		guard let bearer = request.headers.bearer else { return nil }

		do {
			return try await authTokens.validate(token: bearer.token)
		} catch {
			return nil
		}
	}

	func authenticate(authToken: HonkAuthTokens.AuthToken) async throws -> User? {
		guard let user = try await database.read({ db in
			try User.where { $0.firebaseUid.eq(authToken.sub.value) }.fetchOne(db)
		}) else { return nil }

		return user
	}
}
