import Foundation
import Hummingbird

struct APIInterest: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	struct Avatar: Equatable, Hashable, Codable, ResponseCodable, Sendable {
		var userId: String
		var avatarURL: String?
		var avatarBlurhash: String?
	}

	var _id: String
	var categoryId: String
	var interestId: String
	var order: Int?
	var text: String
	var likeCount: Int?
	var description: String?
	var avatars: [Avatar]?
	var popularityRank: Int?
}
