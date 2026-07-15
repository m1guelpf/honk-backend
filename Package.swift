// swift-tools-version: 6.3

import PackageDescription

let package = Package(
	name: "HonkBackend",
	platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18)],
	products: [
		.executable(name: "HonkBackend", targets: ["HonkBackend"]),
	],
	dependencies: [
		.package(url: "https://github.com/vapor/jwt-kit.git", from: "5.5.0"),
		.package(url: "https://github.com/velocityzen/FileType", from: "2.2.1"),
		.package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.6.0"),
		.package(url: "https://github.com/ProxymanApp/atlantis.git", from: "1.36.0"),
		.package(url: "https://github.com/SwiftyLab/MetaCodable.git", from: "1.0.0"),
		.package(url: "https://github.com/vapor/multipart-kit.git", exact: "5.0.0-alpha.5"),
		.package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "5.0.0"),
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
				.product(name: "FileType", package: "FileType"),
				.product(name: "Crypto", package: "swift-crypto"),
				.product(name: "SQLiteData", package: "sqlite-data"),
				.product(name: "Hummingbird", package: "hummingbird"),
				.product(name: "MetaCodable", package: "MetaCodable"),
				.product(name: "MultipartKit", package: "multipart-kit"),
				.product(name: "HummingbirdRouter", package: "hummingbird"),
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "Configuration", package: "swift-configuration"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
				.product(name: "HummingbirdWebSocket", package: "hummingbird-websocket"),
				.product(name: "Atlantis", package: "atlantis", condition: .when(platforms: [.macOS])),
			],
			path: "src",
			swiftSettings: [
				.define("DEBUG", .when(configuration: .debug)),
			]
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
