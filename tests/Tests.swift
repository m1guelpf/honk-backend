import Logging
import Testing
import Foundation
import Hummingbird
@testable import HonkBackend
import Configuration
import HummingbirdTesting
import HummingbirdWSTesting
import InlineSnapshotTesting
import SnapshotTestingCustomDump

let config = ConfigReader(providers: [
	InMemoryProvider(values: [
		"http.port": "0",
		"log.level": "trace",
		"http.host": "127.0.0.1",
	]),
])

@Suite
struct Tests {
	@Test func ws() async throws {
		let app = configure(using: config)

		try await app.test(.live) { client in
			let closeFrame = try await client.ws("/ws") { inbound, outbound, _ in
				try await outbound.write(.text("Hello"))

				var inboundIterator = inbound.messages(maxSize: .max).makeAsyncIterator()
				let message = try await inboundIterator.next()
				#expect(message == .text("Text message, length: 5"))
			}
			#expect(closeFrame?.closeCode == .normalClosure)
		}
	}
}
