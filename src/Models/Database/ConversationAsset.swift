import Foundation
import SQLiteData

@Table
struct ConversationAsset {
	@Selection struct ID: Equatable, Hashable {
		var conversationId: Conversation.ID
		var senderId: User.ID
	}

	var id: ID
	var assetId: Asset.ID
	var recordedAt: Date?
	var playedAt: Date?
	var completedAt: Date?
	var pausedAt: Date?
	var updatedAt: Date
}

extension ConversationAsset {
	static func persist(_ event: ClientEvent.ChatAsset, from userID: User.ID) async throws {
		guard let kind = Asset.Kind(rawValue: event.data.assetType) else { return }
		let contentID = event.data.contentID.uuidString

		@Dependency(\.date.now) var now
		@Dependency(\.defaultDatabase) var database
		try await database.write { db in
			guard let conversation = try Conversation.between(userID, and: event.to).fetchOne(db) else { return }

			try Asset.upsert {
				Asset(
					id: contentID,
					ownerId: userID,
					kind: kind,
					storageRef: "assets/\(contentID)",
					blurHash: event.data.blurHash,
					parameters: event.data,
					thumbnails: nil,
					includesCaption: !event.data.caption.isEmpty,
					metadata: nil,
					createdAt: now
				)
			}
			.execute(db)

			try ConversationAsset.upsert {
				ConversationAsset(
					id: ConversationAsset.ID(conversationId: conversation.id, senderId: userID),
					assetId: contentID,
					recordedAt: nil,
					playedAt: nil,
					completedAt: nil,
					pausedAt: nil,
					updatedAt: now
				)
			}
			.execute(db)
		}
	}
}
