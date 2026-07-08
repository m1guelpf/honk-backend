import Foundation
import Hummingbird

struct APIFriendshipInfo: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	enum State: String, Equatable, Hashable, Codable, ResponseCodable, Sendable {
		case pending, active
	}

	var id: String
	var users: [User.ID]?
	var isStarted: Bool
	var isTemporary: Bool?
	var state: State
	var stats: APIConversationStats
	var lastActivity: Date
	var currentStreakCount: Int?
	var bestStreakCount: Int?
	var score: Int?
	var createdAt: Date
	var creatorId: String?
	var compliments: [APISentCompliment]?
	var isDiscoverFriendship: Bool?
	var requestStatus: State?
	var userRequested: String?
	var interestId: String?
	var likelyOffensive: Bool?
	var isFromTopPick: Bool?
}

extension APIFriendshipInfo {
	struct Context {
		var conversation: Conversation?
		var state: APIFriendshipInfo.State
		var requestStatus: APIFriendshipInfo.State? = nil
		var compliments: [APISentCompliment]? = nil
	}

	init(from friendship: Friendship, with context: Context) {
		id = friendship.id
		users = [friendship.userLowId, friendship.userHighId]
		isStarted = context.conversation?.lastActivityAt != nil
		isTemporary = friendship.isTemporary
		state = context.state
		stats = context.conversation.map { APIConversationStats(from: $0.stats) } ?? APIConversationStats()
		lastActivity = context.conversation?.lastActivityAt ?? friendship.updatedAt
		currentStreakCount = friendship.currentStreakCount
		bestStreakCount = friendship.bestStreakCount
		score = friendship.score
		createdAt = friendship.createdAt
		creatorId = friendship.creator
		compliments = context.compliments
		isDiscoverFriendship = friendship.isDiscover
		requestStatus = context.requestStatus ?? context.state
		userRequested = friendship.friendId(besides: friendship.creator)
		interestId = friendship.interestId
		likelyOffensive = friendship.likelyOffensive
		isFromTopPick = friendship.isFromTopPick
	}
}

extension APIFriendshipInfo.State {
	init(from friendship: Friendship) {
		self = friendship.state == .accepted ? .active : .pending
	}
}
