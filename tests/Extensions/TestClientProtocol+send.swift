import Testing
import Foundation
@testable import HonkBackend
import Hummingbird
import Dependencies
import HummingbirdTesting
import HummingbirdWSClient
import HummingbirdWebSocket
import HummingbirdWSTesting

fileprivate let encoder = JSONEncoder()
fileprivate let allocator = ByteBufferAllocator()

extension TestClientProtocol {
	func send<Return>(
		_ method: HTTPRequest.Method,
		to path: String,
		auth: TestAuthentication? = nil,
		headers: HTTPFields = [:],
		body: ByteBuffer? = nil,
		then: @escaping (TestResponse) async throws -> Return = { $0 }
	) async throws {
		let authHeaders = auth.map { $0.apply(headers: headers) }
		try await execute(uri: path, method: method, headers: authHeaders ?? headers, body: body, testCallback: then)
	}

	func send<T: Encodable, Return>(
		_ method: HTTPRequest.Method,
		to path: String,
		auth: TestAuthentication? = nil,
		headers: HTTPFields = [:],
		body: T,
		then: @escaping (TestResponse) async throws -> Return = { $0 }
	) async throws {
		encoder.dateEncodingStrategy = .honk
		let authHeaders = auth.map { $0.apply(headers: headers) }
		let body = try encoder.encodeAsByteBuffer(body, allocator: allocator)

		try await execute(
			uri: path,
			method: method,
			headers: (authHeaders ?? headers).appending(.init(name: .contentType, value: "application/json")),
			body: body,
			testCallback: then
		)
	}

	func get<Return>(
		_ path: String,
		auth: TestAuthentication? = nil,
		headers: HTTPFields = [:],
		then: @escaping (TestResponse) async throws -> Return = { $0 }
	) async throws {
		try await send(.get, to: path, auth: auth, headers: headers, then: then)
	}

	func get<Return>(
		_ path: String,
		actingAs userID: User.ID,
		headers: HTTPFields = [:],
		then: @escaping (TestResponse) async throws -> Return = { $0 }
	) async throws {
		@Dependency(\.authTokens) var authTokens

		let (token, _) = try await authTokens.generate(for: userID)
		try await get(path, auth: .bearer(token), headers: headers, then: then)
	}

	func post<T: Encodable, Return>(
		_ path: String,
		auth: TestAuthentication? = nil,
		body: T,
		headers: HTTPFields = [:],
		then: @escaping (TestResponse) async throws -> Return = { $0 }
	) async throws {
		try await send(.post, to: path, auth: auth, headers: headers, body: body, then: then)
	}

	func post<T: Encodable, Return>(
		_ path: String,
		actingAs userID: User.ID,
		body: T,
		headers: HTTPFields = [:],
		then: @escaping (TestResponse) async throws -> Return = { $0 }
	) async throws {
		@Dependency(\.authTokens) var authTokens

		let (token, _) = try await authTokens.generate(for: userID)
		try await post(path, auth: .bearer(token), body: body, headers: headers, then: then)
	}

	@discardableResult public func ws(
		_ path: String,
		auth: TestAuthentication? = nil,
		handler: @Sendable @escaping (AsyncStream<ServerEvent>, WebSocketOutboundWriter, WebSocketClient.Context) async throws -> Void
	) async throws -> WebSocketCloseFrame? {
		let config = WebSocketClientConfiguration(additionalHeaders: auth.map { $0.apply(headers: [:]) } ?? [:])

		return try await ws(path, configuration: config) { inbound, outbound, context in
			let (serverEvents, continuation) = AsyncStream.makeStream(of: ServerEvent.self)

			let inboundTask = Task {
				defer { continuation.finish() }

				do {
					let decoder = JSONDecoder.withHonkDateDecoding()
					for try await message in inbound.messages(maxSize: .max) {
						try Task.checkCancellation()
						guard case let .binary(frame) = message else {
							Issue.record("Expected a binary WebSocket message.")
							return
						}

						continuation.yield(try decoder.decode(ServerEvent.self, from: frame))
					}
				} catch {
					if !Task.isCancelled { Issue.record(error) }
				}
			}
			defer { inboundTask.cancel() }

			try await handler(serverEvents, outbound, context)
			try await outbound.close(.normalClosure, reason: nil)
			await inboundTask.value
		}
	}

	@discardableResult public func ws(
		_ path: String,
		actingAs userID: User.ID,
		handler: @Sendable @escaping (AsyncStream<ServerEvent>, WebSocketOutboundWriter, WebSocketClient.Context) async throws -> Void
	) async throws -> WebSocketCloseFrame? {
		@Dependency(\.authTokens) var authTokens

		// `.live` server handlers (used for webhook testing) don't inherit the suite's constant-date override, so validation will happen against the real clock.
		let (token, _) = try await withDependencies { $0.date = .constant(Date()) } operation: {
			try await authTokens.generate(for: userID)
		}

		return try await ws(path, auth: .bearer(token), handler: handler)
	}
}

// MARK: - Authentication

public enum TestAuthentication: Equatable {
	case bearer(String)

	func apply(headers: HTTPFields) -> HTTPFields {
		switch self {
			case let .bearer(token):
				var headers = headers
				headers[.authorization] = "Bearer \(token)"
				return headers
		}
	}
}
