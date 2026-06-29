import JWTKit
import Testing
@testable import HonkBackend
import Dependencies
import HummingbirdTesting
import InlineSnapshotTesting
import DependenciesTestSupport
import SnapshotTestingCustomDump

extension Tests {
	@Suite(.dependencies { try $0.bootstrapDatabase() })
	struct AuthController {}
}

extension Tests.AuthController {
	@Test func cannotLoginWithTestToken() async throws {
		let app = configure()

		try await app.test(.router) { client in
			try await client.post("/login/token", body: LoginWithTokenRequest(isTestToken: true, token: "")) { response in
				#expect(response.status == .badRequest)
				try assertInlineSnapshot(of: response.decode(as: ErrorResponse.self), as: .customDump) {
					"""
					ErrorResponse(
					  statusCode: HTTPResponse.Status(
					    code: 400,
					    reasonPhrase: ""
					  ),
					  errorCode: "malformedRequest",
					  message: "Test tokens are not currently supported."
					)
					"""
				}
			}
		}
	}

	@Test func canLoginWithValidFirebaseToken() async throws {
		@Dependency(\.date.now) var now
		@Dependency(\.authTokens) var authTokens
		@Dependency(\.firebaseVerifier) var firebase

		let app = configure()
		let firebaseToken = try await firebase.generate(userID: "test-userid")

		try await app.test(.router) { client in
			try await client.post("/login/token", body: LoginWithTokenRequest(isTestToken: false, token: firebaseToken)) { response in
				#expect(response.status == .ok)

				let response = try response.decode(as: AuthenticationResponse.self)
				#expect(response.user == nil)
				#expect(response.expiresAt.is(now.adding(.weeks(1))))

				let token = try await authTokens.validate(token: response.token)
				#expect(token.sub.value == "test-userid")
				#expect(token.exp.value.is(now.adding(.weeks(1))))
			}
		}
	}
}
