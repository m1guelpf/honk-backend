import Foundation
import Hummingbird

struct SendMessageRequest: Codable, Sendable {
	// TODO: support more message types
	enum MessageType: String, Codable, Sendable {
		case text
	}

	var type: MessageType
	var message: String
	var isTemporary: Bool
	var date: Date
}
