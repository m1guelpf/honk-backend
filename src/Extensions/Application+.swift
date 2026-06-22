import Logging
import Hummingbird
import Dependencies
import Configuration
import HummingbirdRouter
import HummingbirdWebSocket

// MARK: - Initializers

extension Application {
	/// Creates an instance of `Application` using the provided configuration and routes.
	/// - Parameter config: The configuration reader to use for the application.
	/// - Parameter routes: A closure that defines the routes and middleware for the application.
	init<Handler: MiddlewareProtocol>(@MiddlewareFixedTypeBuilder<Request, Response, HonkRequestContext> routes: () -> Handler) where
		Handler.Input == Request,
		Handler.Output == Response,
		Handler.Context == HonkRequestContext,
		Responder == RouterBuilder<HonkRequestContext, Handler>
	{
		@Dependency(\.config) var config

		let logger = {
			var logger = Logger(label: "HonkBackend")
			logger.logLevel = config.string(forKey: "log.level", as: Logger.Level.self, default: .info)
			return logger
		}()

		let router = RouterBuilder(context: HonkRequestContext.self, builder: routes)

		self.init(router: router, configuration: ApplicationConfiguration(reader: config.scoped(to: "http")), logger: logger)
	}

	/// Creates an instance of `Application` using the provided configuration, routes, and WebSocket router.
	/// - Parameter config: The configuration reader to use for the application.
	/// - Parameter routes: A closure that defines the routes and middleware for the application.
	/// - Parameter webSocketMiddleware: A closure that defines the middleware for handling WebSocket connections.
	/// - Parameter webSocketRouter: A closure that defines how to handle WebSocket messages.
	init<Handler: MiddlewareProtocol, WebSocketMiddleware: MiddlewareProtocol>(
		@MiddlewareFixedTypeBuilder<Request, Response, HonkRequestContext> routes: () -> Handler,
		@MiddlewareFixedTypeBuilder<Request, Response, HonkRequestContext> webSocketMiddleware: () -> WebSocketMiddleware = { LogRequests(.info) },
		onWebSocket: @escaping @Sendable (_ message: WebSocketMessage, _ writer: WebSocketOutboundWriter) async throws -> Void
	) where
		Handler.Input == Request, WebSocketMiddleware.Input == Request,
		Handler.Output == Response, WebSocketMiddleware.Output == Response,
		Handler.Context == HonkRequestContext, WebSocketMiddleware.Context == HonkRequestContext,
		Responder == RouterBuilder<HonkRequestContext, Handler>
	{
		@Dependency(\.config) var config

		let logger = {
			var logger = Logger(label: "HonkBackend")
			logger.logLevel = config.string(forKey: "log.level", as: Logger.Level.self, default: .info)
			return logger
		}()

		let router = RouterBuilder(context: HonkRequestContext.self, builder: routes)

		let webSocketRouter = Router(context: HonkRequestContext.self)
		webSocketRouter.addMiddleware(buildMiddlewareStack: webSocketMiddleware)
		webSocketRouter.ws("/ws") { _, _ in .upgrade() } onUpgrade: { inbound, outbound, _ in
			for try await message in inbound.messages(maxSize: 1_000_000) {
				try await onWebSocket(message, outbound)
			}
		}

		self.init(
			router: router,
			server: .http1WebSocketUpgrade(webSocketRouter: webSocketRouter),
			configuration: ApplicationConfiguration(reader: config.scoped(to: "http")),
			logger: logger
		)
	}
}
