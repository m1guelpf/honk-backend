import Logging
import Hummingbird
import Configuration
import HummingbirdRouter
import HummingbirdWebSocket

func configure() -> some ApplicationProtocol {
	Application {
		SerializeErrors()
		LogRequests(.info)
		AuthenticateUsers()

		AppController()
		AuthController()
		OnboardingController()

		RouteGroup(context: AuthContext.self) {
			UsersController()
		}
	} onWebSocket: { message, writer in
		switch message {
			case let .binary(buffer): try await writer.write(.text("Binary message, length: \(buffer.readableBytes)"))
			case let .text(string): try await writer.write(.text("Text message, length: \(string.count)"))
		}
	}
}
