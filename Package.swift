// swift-tools-version: 6.4

import PackageDescription

let package = Package(
	name: "HonkBackend",
	platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18)],
	products: [
		.executable(name: "HonkBackend", targets: ["HonkBackend"]),
	],
	dependencies: [
		.package(url: "https://github.com/vapor/jwt-kit.git", from: "5.5.0"),
		.package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.6.0"),
		.package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.14.0"),
		.package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.25.0"),
		.package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.19.0"),
		.package(url: "https://github.com/hummingbird-project/hummingbird-websocket.git", from: "2.7.0"),
		.package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0", traits: [.defaults, "CommandLineArguments"]),
	],
	targets: [
		.executableTarget(
			name: "HonkBackend",
			dependencies: [
				.product(name: "JWTKit", package: "jwt-kit"),
				.product(name: "SQLiteData", package: "sqlite-data"),
				.product(name: "Hummingbird", package: "hummingbird"),
				.product(name: "HummingbirdRouter", package: "hummingbird"),
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "Configuration", package: "swift-configuration"),
				.product(name: "HummingbirdWebSocket", package: "hummingbird-websocket"),
			],
			path: "src"
		),

		.testTarget(
			name: "HonkBackendTests",
			dependencies: [
				.byName(name: "HonkBackend"),
				.product(name: "HummingbirdTesting", package: "hummingbird"),
				.product(name: "DependenciesTestSupport", package: "swift-dependencies"),
				.product(name: "HummingbirdWSTesting", package: "hummingbird-websocket"),
				.product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
				.product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
			],
			path: "tests"
		),
	]
)
