import Logging
import Hummingbird
import Dependencies
import Configuration
import ServiceLifecycle
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
			"agora.appId", "agora.appCertificate",
			"twilio.serviceId", "twilio.accountId", "twilio.token",
			"firebase.appIdentifier", "firebase.serviceAccount", "firebase.bucket",
			"apns.keyId", "apns.teamId", "apns.topic", "apns.privateKey", "apns.environment"
		)

		try prepareDependencies {
			$0.config = config
			try $0.bootstrapDatabase()
		}

		let app = configure()
		let services = ServiceGroup(
			services: [CallService(), app],
			gracefulShutdownSignals: [.sigterm, .sigint],
			logger: app.logger
		)
		try await services.run()
	}
}
