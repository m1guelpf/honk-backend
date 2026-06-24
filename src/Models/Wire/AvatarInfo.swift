import Foundation
import Hummingbird

struct AvatarInfo: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var firebaseAuthId: String
	var avatarURL: String
	var avatarBlurHash: String?
}
