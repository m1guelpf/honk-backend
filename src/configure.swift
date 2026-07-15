import Configuration
import Hummingbird
import HummingbirdRouter
import HummingbirdWebSocket
import Logging

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
			AssetsController()
			MomentsController()
			DevicesController()
			FriendsController()
			PhoneVerificationController()
		}
	}
}
