import Configuration

extension ConfigReader {
	func require(keys: ConfigKey...) throws {
		for key in keys {
			_ = try requiredString(forKey: key, isSecret: true)
		}
	}
}
