import Foundation
import Hummingbird

struct SendMessageRequest: Decodable, Sendable {
	// TODO: support more message types
	enum MessageType: String, Decodable, Sendable {
		case text
	}

	var type: MessageType
	var message: String
	var isTemporary: Bool
	var date: Date
}
