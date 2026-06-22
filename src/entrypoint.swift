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

		prepareDependencies { $0.config = config }

		let app = configure()
		try await app.runService()
	}
}
