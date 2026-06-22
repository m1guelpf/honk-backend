import Testing
@testable import HonkBackend
import HummingbirdTesting
import InlineSnapshotTesting
import SnapshotTestingCustomDump

extension Tests {
	@Suite struct AuthController {}
}

extension Tests.AuthController {
	@Test func loginWithTestToken() async throws {
		let app = configure(using: config)

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
}
