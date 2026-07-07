import Foundation
import Hummingbird

struct StatsRequestBody: Decodable, Sendable {
	enum StatsType: String, Decodable, Sendable {
		case chatSession
	}

	struct Payload: Decodable, Sendable {
		var charactersSent: Int
		var imagesSent: Int
		var honksSent: Int
		var audioSent: Int
		var videosSent: Int
	}

	var to: String
	var type: StatsType
	var payload: Payload
}
