import SQLiteData
import Foundation

@Table
struct Friendship: Identifiable {
	let id: String
	var userLowId: User.ID
	var userHighId: User.ID
	var state: String
	var creator: User.ID
	var requestMessage: String?
	var isTemporary: Bool
	var isDiscover: Bool
	var isFromTopPick: Bool
	var interestId: String?
	var currentStreakCount: Int
	var bestStreakCount: Int
	var lastStreakDate: Date?
	var score: Int?
	var likelyOffensive: Bool
	var lastActivityAt: Date?
	var createdAt: Date
	var updatedAt: Date
}
