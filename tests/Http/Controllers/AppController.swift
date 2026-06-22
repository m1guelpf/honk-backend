import Testing
@testable import HonkBackend
import HummingbirdTesting
import InlineSnapshotTesting
import SnapshotTestingCustomDump

extension Tests {
	@Suite struct AppController {}
}

extension Tests.AppController {
	@Test func `init`() async throws {
		let app = configure(using: config)

		try await app.test(.router) { client in
			try await client.get("/app/init") { response in
				#expect(response.status == .ok)
				try assertInlineSnapshot(of: response.decode(as: InitializationResponse.self), as: .customDump)
			}
		}
	}
}
