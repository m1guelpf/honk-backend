import SQLiteData
import Foundation

@Table
struct Message: Identifiable, Equatable, Hashable {
	@Selection struct ID: Equatable, Hashable, Codable {
		var conversationId: Conversation.ID
		var senderId: User.ID
	}

	var id: ID
	var text: String?
	var isOriginal: Bool
	var reaction: String?
	var reactionAt: Date?
	var updatedAt: Date
}

// MARK: - Codable

extension Message: Codable {
	private enum CodingKeys: CodingKey {
		case conversationId, senderId, text, isOriginal, reaction, reactionAt, updatedAt
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		id = try .init(
			conversationId: container.decode(Conversation.ID.self, forKey: .conversationId),
			senderId: container.decode(User.ID.self, forKey: .senderId)
		)
		text = try container.decodeIfPresent(String.self, forKey: .text)
		isOriginal = try container.decode(Bool.self, forKey: .isOriginal)
		reaction = try container.decodeIfPresent(String.self, forKey: .reaction)
		reactionAt = try container.decodeIfPresent(Date.self, forKey: .reactionAt)
		updatedAt = try container.decode(Date.self, forKey: .updatedAt)
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		try container.encode(id.conversationId, forKey: .conversationId)
		try container.encode(id.senderId, forKey: .senderId)
		try container.encodeIfPresent(text, forKey: .text)
		try container.encode(isOriginal, forKey: .isOriginal)
		try container.encodeIfPresent(reaction, forKey: .reaction)
		try container.encodeIfPresent(reactionAt, forKey: .reactionAt)
		try container.encode(updatedAt, forKey: .updatedAt)
	}
}
