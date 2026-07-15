import Logging
import Hummingbird
import Dependencies
import Configuration
import HummingbirdRouter
#if DEBUG && os(macOS)
import Atlantis
#endif

@main
struct Entrypoint {
	static func main() async throws {
		#if DEBUG && os(macOS)
		Atlantis.start()
		#endif

		let config = try await ConfigReader(providers: [
			CommandLineArgumentsProvider(),
			EnvironmentVariablesProvider(),
			EnvironmentVariablesProvider(environmentFilePath: ".env", allowMissing: true),
			InMemoryProvider(values: [
				"http.serverName": "Honk",
			]),
		])

		try config.require(
			"jwt.key", "database.path",
			"twilio.serviceId", "twilio.accountId", "twilio.token",
			"firebase.appIdentifier", "firebase.serviceAccount", "firebase.bucket"
		)

		try prepareDependencies {
			$0.config = config
			try $0.bootstrapDatabase()
		}

		let app = configure()
		try await app.runService()
	}
}
