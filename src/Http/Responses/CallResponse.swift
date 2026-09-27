import Foundation
import Hummingbird

struct CallResponse: ResponseEncodable {
	var channelName: UUID
	var key: String
	var call: APICall
}

struct AcceptCallResponse: ResponseEncodable {
	var channelName: UUID
	var key: String
}
