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

		AppController()
		AuthController()
		ContactsController()
		OnboardingController()

		RouteGroup(context: AuthContext.self) {
			ChatController()
			GameController()
			UsersController()
			StatsController()
			MomentsController()
			DevicesController()
			FriendsController()
			PhoneVerificationController()
		}
	}
}
