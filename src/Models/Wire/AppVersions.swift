import Foundation
import Hummingbird

struct AppVersions: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	struct VersionInfo: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		var versionNumber: String
		var buildNumber: String
		var requiredOSVersion: String
	}

	var latestVersionInfo: VersionInfo
	var requiredVersionInfo: VersionInfo
}
