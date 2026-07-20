import Foundation
import Hummingbird

struct APIFriendConversation: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	struct EncodedAsset: Equatable, Hashable, Sendable {
		var value: Data
	}

	var friendId: String
	var yourMessage: String?
	var theirMessage: String?
	var yourDate: APITimestamp?
	var theirDate: APITimestamp?
	var yourAsset: EncodedAsset?
	var theirAsset: EncodedAsset?
	var yourAssetData: Asset.Parameters?
	var theirAssetData: Asset.Parameters?
}

extension APIFriendConversation {
	init(friendId: String, theirMessage: Message?, yourMessage: Message?) {
		self.friendId = friendId
		self.yourMessage = yourMessage?.text
		self.theirMessage = theirMessage?.text
		yourDate = (yourMessage?.updatedAt as Date?).map { APITimestamp($0) }
		theirDate = (theirMessage?.updatedAt as Date?).map { APITimestamp($0) }
	}
}

// MARK: - Codable

extension APIFriendConversation.EncodedAsset: Codable {
	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()

		guard let value = try Data(base64Encoded: container.decode(String.self)) else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid base64-encoded string")
		}

		self.value = value
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(value.base64EncodedString())
	}
}
