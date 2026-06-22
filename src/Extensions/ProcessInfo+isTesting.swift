import Foundation

fileprivate extension ProcessInfo {
	var isTesting: Bool {
		if environment.keys.contains("BAZEL_TEST") { return true }
		if environment.keys.contains("XCTestBundlePath") { return true }
		if environment.keys.contains("XCTestBundleInjectPath") { return true }
		if environment.keys.contains("XCTestSessionIdentifier") { return true }
		if environment.keys.contains("XCTestConfigurationFilePath") { return true }

		return arguments.contains { argument in
			let path = URL(fileURLWithPath: argument)

			return path.pathExtension == "xctest"
				|| argument == "--testing-library"
				|| path.lastPathComponent == "xctest"
				|| path.lastPathComponent == "swiftpm-testing-helper"
		}
	}
}
