import Foundation
import Hummingbird

struct APIGameModel: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var id: String
	var friendshipId: Friendship.ID
	var gameType: Game.GameType
	var users: [User.ID]
	var startedBy: User.ID
	var accepted: [User.ID]
	var declined: [User.ID]
	var previousGameId: String?
	var endedAt: Date?
	var wasCancelled: Bool?
	var hasMoved: Bool?
}

extension APIGameModel {
	init(from game: Game, friendship: Friendship) {
		id = game.id
		friendshipId = game.friendshipId
		gameType = game.gameType
		users = [friendship.userLowId, friendship.userHighId]
		startedBy = game.fromUserId
		accepted = [] // TODO: we're not currently tracking this
		declined = [] // TODO: we're not currently tracking this
		previousGameId = nil // TODO: we're not currently tracking this
		endedAt = game.status == "ended" ? game.updatedAt : nil // TODO: should we store an `endedAt` field in the games table?
		wasCancelled = game.status == "cancelled" ? true : nil // TODO: this feels wrong
		hasMoved = nil // TODO: what goes here?
	}
}
