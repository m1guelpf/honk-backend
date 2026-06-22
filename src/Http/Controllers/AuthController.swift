import Foundation
import Hummingbird
import Dependencies
import HummingbirdRouter

struct AuthController: RouterController {
	var body: some RouterMiddleware<Context> {
		Post("login/token", handler: loginWithToken)
	}

	func loginWithToken(_ request: Request, context: Context) async throws -> RawAuthResponse {
		let request = try await request.decode(as: LoginWithTokenRequest.self, context: context)

		guard !request.isTestToken else {
			throw ErrorResponse(.badRequest, code: "malformedRequest", message: "Test tokens are not currently supported.")
		}

		@Dependency(\.firebaseVerifier) var firebase

		let token = try await firebase.verify(token: request.token)

		// TODO: Find or register user in database
		// TODO: Generate JWT for user

		return RawAuthResponse(token: "test-token", expiresAt: Date().advanced(by: 60), user: nil)
	}
}
