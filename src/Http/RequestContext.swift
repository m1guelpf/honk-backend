import Foundation
import Hummingbird
import HummingbirdRouter
import HummingbirdWebSocket

public typealias Context = HonkRequestContext
public typealias AuthContext = AuthedHonkRequestContext

public struct HonkRequestContext: RequestContext, RouterRequestContext, WebSocketRequestContext {
	var user: User?
	var authToken: HonkAuthTokens.AuthToken?

	public var routerContext: RouterBuilderContext
	public var coreContext: CoreRequestContextStorage
	public let webSocket: WebSocketHandlerReference<Self>

	public var requestDecoder: JSONDecoder {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .honk
		return decoder
	}

	public var responseEncoder: JSONEncoder {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .honk
		return encoder
	}

	public init(source: Source) {
		user = nil
		authToken = nil
		webSocket = .init()
		routerContext = .init()
		coreContext = .init(source: source)
	}

	@discardableResult
	func requireAuthToken() throws -> HonkAuthTokens.AuthToken {
		guard let authToken else { throw HTTPError(.unauthorized, message: "Failed to authenticate") }
		return authToken
	}

	@discardableResult
	func requireUser() throws -> User {
		guard let user else { throw HTTPError(.unauthorized, message: "Could not retrieve user") }
		return user
	}
}

public struct AuthedHonkRequestContext: ChildRequestContext, RouterRequestContext {
	public typealias ParentContext = HonkRequestContext

	var user: User
	var authToken: HonkAuthTokens.AuthToken

	public var routerContext: RouterBuilderContext
	public var coreContext: CoreRequestContextStorage

	public var requestDecoder: JSONDecoder {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .honk
		return decoder
	}

	public var responseEncoder: JSONEncoder {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .honk
		return encoder
	}

	/// Allow uploads of up to 100 MB
	public var maxUploadSize: Int {
		100 * 1024 * 1024
	}

	public init(context: ParentContext) throws {
		user = try context.requireUser()
		authToken = try context.requireAuthToken()

		coreContext = context.coreContext
		routerContext = context.routerContext
	}
}
