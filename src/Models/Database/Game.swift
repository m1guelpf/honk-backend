import SQLiteData
import Foundation

@Table
struct Game: Identifiable {
	enum GameType: String, CaseIterable, Codable, Equatable, Hashable, QueryBindable, Sendable {
		case ticTacToe, trivia, trueOrFalse, connectFour, rockPaperScissors, icebreakers
	}

	var id: String
	var friendshipId: Friendship.ID
	var gameType: GameType
	var status: String
	var fromUserId: User.ID
	var state: String?
	var scores: String?
	var createdAt: Date
	var updatedAt: Date
}
