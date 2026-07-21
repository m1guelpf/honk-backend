import Foundation
import SQLiteData

@Table
struct Message: Identifiable, Equatable, Hashable {
	@Selection struct ID: Equatable, Hashable, Codable {
		var conversationId: Conversation.ID
		var senderId: User.ID
	}

	var id: ID
	var text: String?
	var isOriginal: Bool
	var updatedAt: Date
}

// MARK: - Codable

extension Message: Codable {
	private enum CodingKeys: CodingKey {
		case conversationId, senderId, text, isOriginal, updatedAt
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		id = try .init(
			conversationId: container.decode(Conversation.ID.self, forKey: .conversationId),
			senderId: container.decode(User.ID.self, forKey: .senderId)
		)
		text = try container.decodeIfPresent(String.self, forKey: .text)
		isOriginal = try container.decode(Bool.self, forKey: .isOriginal)
		updatedAt = try container.decode(Date.self, forKey: .updatedAt)
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		try container.encode(id.conversationId, forKey: .conversationId)
		try container.encode(id.senderId, forKey: .senderId)
		try container.encodeIfPresent(text, forKey: .text)
		try container.encode(isOriginal, forKey: .isOriginal)
		try container.encode(updatedAt, forKey: .updatedAt)
	}
}
