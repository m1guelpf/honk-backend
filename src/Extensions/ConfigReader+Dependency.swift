import Dependencies
import Configuration

extension ConfigReader: @retroactive DependencyKey {
	public static let liveValue: Configuration.ConfigReader = ConfigReader(providers: [])
}

public extension DependencyValues {
	var config: ConfigReader {
		get { self[ConfigReader.self] }
		set { self[ConfigReader.self] = newValue }
	}
}
