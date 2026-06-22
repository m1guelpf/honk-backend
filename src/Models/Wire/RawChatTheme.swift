import Foundation
import Hummingbird

struct RawChatTheme: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var id: String
	var name: String
	var isHidden: Bool?
	var isForMatching: Bool?
	var isDiscoverTheme: Bool?
	var isPopular: Bool
	var isNew: Bool

	// Chat Bubbles
	var yourBoxBackgroundColor: Color
	var theirBoxBackgroundColor: Color
	var themeIconBackground: Color
	var themeIconGlyph: Color
	var yourBoxBackgroundColorDark: Color?
	var theirBoxBackgroundColorDark: Color?
	var themeIconBackgroundDark: Color?
	var themeIconGlyphDark: Color?

	// Audio-message player controls
	var yourPlayerControls: Color?
	var theirUnplayedPlayerControls: Color?
	var theirPlayedPlayerControls: Color?
	var yourPlayerBackground: Color?
	var theirUnplayedBackground: Color?
	var theirPlayedBackground: Color?
	var yourProgressColor: Color?
	var theirProgressColor: Color?
	var yourPlayerControlsDark: Color?
	var theirUnplayedPlayerControlsDark: Color?
	var theirPlayedPlayerControlsDark: Color?
	var yourPlayerBackgroundDark: Color?
	var theirUnplayedBackgroundDark: Color?
	var theirPlayedBackgroundDark: Color?
	var yourProgressColorDark: Color?
	var theirProgressColorDark: Color?

	// Audio background gradient
	var audioBackgroundTL: Color?
	var audioBackgroundTR: Color?
	var audioBackgroundBL: Color?
	var audioBackgroundBR: Color?
	var audioBackgroundTLDark: Color?
	var audioBackgroundTRDark: Color?
	var audioBackgroundBLDark: Color?
	var audioBackgroundBRDark: Color?

	// Card / photo asset colors
	var yourCardAssetTopColor: Color?
	var yourCardAssetBottomColor: Color?
	var yourCardAssetDropshadow: Color?
	var yourCardAssetTopColorDark: Color?
	var yourCardAssetBottomColorDark: Color?
	var yourCardAssetDropshadowDark: Color?
	var theirCardAssetTopColor: Color?
	var theirCardAssetBottomColor: Color?
	var theirCardAssetDropshadow: Color?
	var theirCardAssetTopColorDark: Color?
	var theirCardAssetBottomColorDark: Color?
	var theirCardAssetDropshadowDark: Color?
}
