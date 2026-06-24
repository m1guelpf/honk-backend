import Hummingbird

public struct RequireAuthToken: RouterMiddleware {
	public func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
		let _ = try context.requireAuthToken()

		return try await next(request, context)
	}
}
