import Foundation
import Hummingbird

struct APIFriendConversation: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	struct Base64String: Equatable, Hashable, Codable, Sendable {
		var value: String
	}

	struct AssetData: Equatable, Hashable, Codable, Sendable {
		// TODO: what goes here?
	}

	var friendId: String
	var yourMessage: String?
	var theirMessage: String?
	var yourDate: APITimestamp?
	var theirDate: APITimestamp?
	var yourAsset: Base64String?
	var theirAsset: Base64String?
	var yourAssetData: AssetData?
	var theirAssetData: AssetData?
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
