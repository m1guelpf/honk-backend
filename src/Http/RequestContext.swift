import Foundation
import Hummingbird
import HummingbirdRouter
import HummingbirdWebSocket

typealias Context = HonkRequestContext

struct HonkRequestContext: RequestContext, RouterRequestContext, WebSocketRequestContext {
	var routerContext: RouterBuilderContext
	var coreContext: CoreRequestContextStorage
	let webSocket: WebSocketHandlerReference<Self>

	var requestDecoder: JSONDecoder {
		var decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return decoder
	}

	var responseEncoder: JSONEncoder {
		var encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		return encoder
	}

	init(source: Source) {
		webSocket = .init()
		routerContext = .init()
		coreContext = .init(source: source)
	}
}
