import Foundation
import Hummingbird
import HummingbirdTesting

fileprivate let encoder = JSONEncoder()
fileprivate let allocator = ByteBufferAllocator()

extension TestClientProtocol {
	func send<Return>(
		_ method: HTTPRequest.Method,
		to path: String,
		headers: HTTPFields = [:],
		body: ByteBuffer? = nil,
		then: @escaping (TestResponse) async throws -> Return = { $0 }
	) async throws {
		try await execute(uri: path, method: method, headers: headers, body: body, testCallback: then)
	}

	func send<T: Encodable, Return>(
		_ method: HTTPRequest.Method,
		to path: String,
		headers: HTTPFields = [:],
		body: T,
		then: @escaping (TestResponse) async throws -> Return = { $0 }
	) async throws {
		let body = try encoder.encodeAsByteBuffer(body, allocator: allocator)

		try await execute(
			uri: path,
			method: method,
			headers: headers.appending(.init(name: .contentType, value: "application/json")),
			body: body,
			testCallback: then
		)
	}

	func get<Return>(
		_ path: String,
		headers: HTTPFields = [:],
		then: @escaping (TestResponse) async throws -> Return = { $0 }
	) async throws {
		try await send(.get, to: path, headers: headers, then: then)
	}

	func post<T: Encodable, Return>(
		_ path: String,
		body: T,
		headers: HTTPFields = [:],
		then: @escaping (TestResponse) async throws -> Return = { $0 }
	) async throws {
		try await send(.post, to: path, headers: headers, body: body, then: then)
	}
}
