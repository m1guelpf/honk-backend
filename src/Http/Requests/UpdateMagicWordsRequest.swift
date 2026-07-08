import Foundation
import Hummingbird

struct UpdateMagicWordsRequest: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var magicWords: [User.MagicWord]
}
