import Logging
import Hummingbird
import Dependencies
import Configuration
import HummingbirdRouter
import HummingbirdWebSocket

// MARK: - Initializers

extension Application {
	/// Creates an instance of `Application` using the provided configuration, routes, and WebSocket router.
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

		let webSocketRouter = Router(context: HonkRequestContext.self)

		webSocketRouter.ws("/chat") { request, _ in
			@Dependency(\.authTokens) var authTokens
			guard let bearer = request.headers.bearer, (try? await authTokens.validate(token: bearer.token)) != nil else { return .dontUpgrade }

			return .upgrade()
		} onUpgrade: { inbound, outbound, context in
			@Dependency(\.authTokens) var authTokens
			guard let bearer = context.request.headers.bearer, let token = try? await authTokens.validate(token: bearer.token) else { return }

			await Connection(userID: token.sub.value).run(inbound: inbound, outbound: outbound)
		}

		self.init(
			router: router,
			server: .http1WebSocketUpgrade(webSocketRouter: webSocketRouter),
			configuration: ApplicationConfiguration(reader: config.scoped(to: "http")),
			logger: logger
		)
	}
}
