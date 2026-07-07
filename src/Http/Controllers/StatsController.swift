import SQLiteData
import Hummingbird
import Dependencies
import HummingbirdRouter

struct StatsController: RouterController {
	var body: some RouterMiddleware<AuthContext> {
		Post("stats", handler: report)
	}

	@Dependency(\.defaultDatabase) var database

	func report(_ request: Request, context: AuthContext) async throws -> [String: String] {
		let body = try await request.decode(as: StatsRequestBody.self, context: context)
		let me = context.user

		var stats = me.stats
		stats.totalHonksSent += body.payload.honksSent
		stats.totalImagesSent += body.payload.imagesSent
		stats.totalCharactersSent += body.payload.charactersSent
		// TODO: User.Stats doesn't model audioSent/videosSent yet

		try await database.write { [stats] db in
			try User.find(me.id).update { $0.stats = #bind(stats) }.execute(db)

			if case .chatSession = body.type,
			   let conversation = try Friendship.where({ $0.involves(me.id) && $0.involves(body.to) }).leftJoin(Conversation.all, on: { $1.friendshipId.eq($0.id) }).select({ $1 }).fetchOne(db).flatten()
			{
				var conversationStats = conversation.stats
				conversationStats.totalHonksSent = body.payload.honksSent
				conversationStats.totalImagesSent = body.payload.imagesSent
				conversationStats.totalCharactersSent = body.payload.charactersSent
				// TODO: User.Stats doesn't model audioSent/videosSent yet

				try Conversation.find(conversation.id).update { $0.stats = #bind(conversationStats) }.execute(db)
			}
		}

		return [:]
	}
}
