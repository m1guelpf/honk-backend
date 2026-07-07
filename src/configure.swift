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
			UsersController()
			DevicesController()
			FriendsController()
			PhoneVerificationController()
			StatsController()
		}
	} onWebSocket: { message, writer in
		print(message)

		switch message {
			case let .binary(buffer): try await writer.write(.text("Binary message, length: \(buffer.readableBytes)"))
			case let .text(string): try await writer.write(.text("Text message, length: \(string.count)"))
		}
	}
}
