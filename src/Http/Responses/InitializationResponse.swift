import Foundation
import Hummingbird

struct InitializationResponse: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	struct FeatureFlag: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		var _id: String
		var feature: String
		var enabled: Bool
	}

	struct RawBioDescription: Equatable, Hashable, ResponseCodable, Codable, Sendable {
		var id: String
		var color: APIColor
		var colorDark: APIColor
	}

	struct PopularInterest: Equatable, Hashable, ResponseCodable, Codable, Sendable {
		var _id: String
		var interest: APIInterest
	}

	struct InterestCategory: Equatable, Hashable, ResponseCodable, Codable, Sendable {
		var _id: String
		var id: String
		var order: Int?
		var text: String
		var color: APIColor
		var interests: [APIInterest]
	}

	struct ServerMessage: Equatable, Hashable, ResponseCodable, Codable, Sendable {
		var _id: String
		var title: String
		var body: String
		var buttonCopy: String?
	}

	var currentVersion = "1.7.3"
	var currentBuild = "20220125030111"
	var minimumVersion = "1.0.0"
	var requiredAppVersion: String? = nil
	var themes: [APIChatTheme] = []
	var doubleTapEmoji = "❤️"
	var bios: [RawBioDescription]? = .default
	var features: [FeatureFlag]? = nil
	var popularInterests: [PopularInterest]? = nil
	var categories: [InterestCategory]? = nil
	var compliments: [APICompliment]? = nil
	var mostRecentInterests: [String]? = nil
	var disableDiffEndpoints: Bool? = false
	var message: ServerMessage? = nil
	var sunsetMessage: ServerMessage? = nil
}

extension [InitializationResponse.RawBioDescription] {
	static let `default` = [
		InitializationResponse.RawBioDescription(
			id: "blue",
			color: APIColor(red: 0.36, green: 0.61, blue: 0.96, alpha: 1.0),
			colorDark: APIColor(red: 0.20, green: 0.40, blue: 0.75, alpha: 1.0)
		),
		InitializationResponse.RawBioDescription(
			id: "yellow",
			color: APIColor(red: 0.99, green: 0.83, blue: 0.30, alpha: 1.0),
			colorDark: APIColor(red: 0.78, green: 0.62, blue: 0.12, alpha: 1.0)
		),
		InitializationResponse.RawBioDescription(
			id: "green",
			color: APIColor(red: 0.40, green: 0.80, blue: 0.45, alpha: 1.0),
			colorDark: APIColor(red: 0.22, green: 0.55, blue: 0.28, alpha: 1.0)
		),
		InitializationResponse.RawBioDescription(
			id: "pink",
			color: APIColor(red: 0.96, green: 0.55, blue: 0.72, alpha: 1.0),
			colorDark: APIColor(red: 0.74, green: 0.35, blue: 0.52, alpha: 1.0)
		),
		InitializationResponse.RawBioDescription(
			id: "peach",
			color: APIColor(red: 0.99, green: 0.70, blue: 0.55, alpha: 1.0),
			colorDark: APIColor(red: 0.78, green: 0.50, blue: 0.36, alpha: 1.0)
		),
		InitializationResponse.RawBioDescription(
			id: "grey",
			color: APIColor(red: 0.60, green: 0.62, blue: 0.66, alpha: 1.0),
			colorDark: APIColor(red: 0.38, green: 0.40, blue: 0.44, alpha: 1.0)
		),
	]
}
