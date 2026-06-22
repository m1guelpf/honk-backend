import Foundation
import Hummingbird

struct ExploreAvatarInfo: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var userId: String
	var avatarURL: String?
	var avatarBlurhash: String?
}
