import Logging
import Hummingbird
import Dependencies
import Configuration
import HummingbirdRouter

@main
struct Entrypoint {
	static func main() async throws {
		let config = try await ConfigReader(providers: [
			CommandLineArgumentsProvider(),
			EnvironmentVariablesProvider(),
			EnvironmentVariablesProvider(environmentFilePath: ".env", allowMissing: true),
			InMemoryProvider(values: [
				"http.serverName": "Honk",
			]),
		])

		try config.require(keys: "jwt.key", "database.path", "firebase.appIdentifier")

		try prepareDependencies {
			$0.config = config
			try $0.bootstrapDatabase()
		}

		let app = configure()
		try await app.runService()
	}
}
