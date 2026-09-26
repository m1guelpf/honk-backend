import Testing
import Foundation
import Dependencies
import Configuration
import DependenciesTestSupport

// MARK: - Base Test Suite

@Suite(.dependencies {
	$0.uuid = .incrementing
	$0.continuousClock = .immediate
	$0.config = ConfigReader(providers: [$0.testConfig])
	$0.date = .constant(Date(timeIntervalSince1970: 1_773_878_400))
})
struct Tests {}

// MARK: - Test Helpers

private struct MutableConfigKey: DependencyKey {
	static let liveValue = MutableInMemoryProvider(initialValues: [
		"http.port": "0",
		"log.level": "trace",
		"http.host": "127.0.0.1",
		"firebase.appIdentifier": "honk",
	])
}

extension DependencyValues {
	var testConfig: MutableInMemoryProvider {
		get { self[MutableConfigKey.self] }
		set { self[MutableConfigKey.self] = newValue }
	}
}
