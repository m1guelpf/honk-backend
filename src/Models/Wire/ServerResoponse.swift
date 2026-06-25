import Foundation
import Hummingbird

struct ServerResponse: Error, Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var statusCode: HTTPResponse.Status
	var code: String?
	var message: String

	init(_ statusCode: HTTPResponse.Status, code: String? = nil, message: String) {
		self.code = code
		self.message = message
		self.statusCode = statusCode
	}
}
