import Foundation
import Hummingbird

struct Interest: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var _id: String
	var categoryId: String
	var interestId: String
	var order: Int?
	var text: String
	var likeCount: Int?
	var description: String?
	var avatars: [ExploreAvatarInfo]?
	var popularityRank: Int?
}
