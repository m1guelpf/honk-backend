import Logging
import Testing
import Foundation
import Hummingbird
@testable import HonkBackend
import Dependencies
import Configuration
import HummingbirdTesting
import HummingbirdWSTesting
import InlineSnapshotTesting
import DependenciesTestSupport
import SnapshotTestingCustomDump

// MARK: - Base Test Suite

@Suite(.dependencies {
	$0.uuid = .incrementing
	$0.config = ConfigReader(providers: [$0.testConfig])
	$0.date = .constant(Date(timeIntervalSince1970: 1_773_878_400))
})
struct Tests {}

// MARK: - WebSocket Tests

extension Tests {
	@Test func ws() async throws {
		let app = configure()

		try await app.test(.live) { client in
			let closeFrame = try await client.ws("/chat") { inbound, outbound, _ in
				try await outbound.write(.text("Hello"))

				var inboundIterator = inbound.messages(maxSize: .max).makeAsyncIterator()
				let message = try await inboundIterator.next()
				#expect(message == .text("Text message, length: 5"))
			}
			#expect(closeFrame?.closeCode == .normalClosure)
		}
	}
}

// MARK: - Test Helpers

private struct MutableConfigKey: DependencyKey {
	static let liveValue = MutableInMemoryProvider(initialValues: [
		"http.port": "0",
		"log.level": "trace",
		"http.host": "127.0.0.1",
		"firebase.appIdentifier": "honk",
	])
}

extension DependencyValues {
	var testConfig: MutableInMemoryProvider {
		get { self[MutableConfigKey.self] }
		set { self[MutableConfigKey.self] = newValue }
	}
}
