import Testing
import NIOCore
import Foundation
@testable import HonkBackend
import Hummingbird
import Dependencies
import HummingbirdTesting
import HummingbirdWSTesting

extension Connection {
	func test(
		run block: @Sendable @escaping (AsyncStream<ServerEvent>, @Sendable (ClientEvent) async throws -> Void) async throws -> Void
	) async throws {
		let dependencies = withEscapedDependencies { $0 }
		let app = Application(
			router: Router(),
			server: .http1WebSocketUpgrade { _, _, _ in
				.upgrade([:]) { inbound, outbound, _ in
					await dependencies.yield { await run(inbound: inbound, outbound: outbound) }
				}
			},
			configuration: .init(address: .hostname("127.0.0.1", port: 0))
		)

		try await app.test(.live) { client in
			_ = try await client.ws("/") { inbound, outbound, _ in
				try await withThrowingTaskGroup(of: Void.self) { group in
					defer { group.cancelAll() }
					group.addTask {
						try await Task.sleep(for: .seconds(10))
						throw ConnectionTestError.timeout
					}
					group.addTask {
						var events = inbound.makeAsyncIterator()
						let ready = await events.next()
						try #require(ready == .ready)

						try await block(inbound) { event in
							try await outbound.write(.binary(ByteBuffer(data: JSONEncoder.withHonkDateEncoding().encode(event))))
						}
					}
					try await group.next()
				}
			}
		}
	}
}

private enum ConnectionTestError: Error {
	case timeout
}
