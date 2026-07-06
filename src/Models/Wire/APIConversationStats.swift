import Foundation
import Hummingbird

struct APIConversationStats: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var honksSent: Int
	var imagesSent: Int
	var charactersSent: Int

	init(honksSent: Int = 0, imagesSent: Int = 0, charactersSent: Int = 0) {
		self.honksSent = honksSent
		self.imagesSent = imagesSent
		self.charactersSent = charactersSent
	}
}

extension APIConversationStats {
	init(from stats: User.Stats) {
		self.init(
			honksSent: stats.totalHonksSent,
			imagesSent: stats.totalImagesSent,
			charactersSent: stats.totalCharactersSent
		)
	}
}
