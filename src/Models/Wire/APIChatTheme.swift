import Foundation
import Hummingbird

struct APIChatTheme: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var id: String
	var name: String
	var isHidden: Bool?
	var isForMatching: Bool?
	var isDiscoverTheme: Bool?
	var isPopular: Bool
	var isNew: Bool

	// Chat Bubbles
	var yourBoxBackgroundColor: APIColor
	var theirBoxBackgroundColor: APIColor
	var themeIconBackground: APIColor
	var themeIconGlyph: APIColor
	var yourBoxBackgroundColorDark: APIColor?
	var theirBoxBackgroundColorDark: APIColor?
	var themeIconBackgroundDark: APIColor?
	var themeIconGlyphDark: APIColor?

	// Audio-message player controls
	var yourPlayerControls: APIColor?
	var theirUnplayedPlayerControls: APIColor?
	var theirPlayedPlayerControls: APIColor?
	var yourPlayerBackground: APIColor?
	var theirUnplayedBackground: APIColor?
	var theirPlayedBackground: APIColor?
	var yourProgressColor: APIColor?
	var theirProgressColor: APIColor?
	var yourPlayerControlsDark: APIColor?
	var theirUnplayedPlayerControlsDark: APIColor?
	var theirPlayedPlayerControlsDark: APIColor?
	var yourPlayerBackgroundDark: APIColor?
	var theirUnplayedBackgroundDark: APIColor?
	var theirPlayedBackgroundDark: APIColor?
	var yourProgressColorDark: APIColor?
	var theirProgressColorDark: APIColor?

	// Audio background gradient
	var audioBackgroundTL: APIColor?
	var audioBackgroundTR: APIColor?
	var audioBackgroundBL: APIColor?
	var audioBackgroundBR: APIColor?
	var audioBackgroundTLDark: APIColor?
	var audioBackgroundTRDark: APIColor?
	var audioBackgroundBLDark: APIColor?
	var audioBackgroundBRDark: APIColor?

	// Card / photo asset colors
	var yourCardAssetTopColor: APIColor?
	var yourCardAssetBottomColor: APIColor?
	var yourCardAssetDropshadow: APIColor?
	var yourCardAssetTopColorDark: APIColor?
	var yourCardAssetBottomColorDark: APIColor?
	var yourCardAssetDropshadowDark: APIColor?
	var theirCardAssetTopColor: APIColor?
	var theirCardAssetBottomColor: APIColor?
	var theirCardAssetDropshadow: APIColor?
	var theirCardAssetTopColorDark: APIColor?
	var theirCardAssetBottomColorDark: APIColor?
	var theirCardAssetDropshadowDark: APIColor?
}
