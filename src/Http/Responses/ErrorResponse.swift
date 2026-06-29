import Foundation
import Hummingbird

struct ErrorResponse: Error, Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var statusCode: HTTPResponse.Status
	var errorCode: String
	var message: String?

	init(_ statusCode: HTTPResponse.Status, code: String, message: String? = nil) {
		errorCode = code
		self.message = message
		self.statusCode = statusCode
	}
}
