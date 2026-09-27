import Logging
import Hummingbird
import Configuration
import HummingbirdRouter
import HummingbirdWebSocket

func configure() -> some ApplicationProtocol {
	Application {
		#if DEBUG && os(macOS)
		AtlantisMiddleware()
		#else
		LogRequests(.info)
		#endif
		SerializeErrors()
		AuthenticateUsers()

		Get("/") { _, _ in
			Response.redirect(to: "https://github.com/m1guelpf/honk-backend", type: .found)
		}

		AppController()
		AuthController()
		ContactsController()
		OnboardingController()

		RouteGroup(context: AuthContext.self) {
			ChatController()
			GameController()
			UsersController()
			StatsController()
			CallsController()
			AssetsController()
			MomentsController()
			DevicesController()
			FriendsController()
			PhoneVerificationController()
		}
	}
}
