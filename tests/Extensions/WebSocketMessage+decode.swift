import WSCore
import Foundation
@testable import HonkBackend

extension WebSocketMessage {
	static let decoder = JSONDecoder.withHonkDateDecoding()

	func decode<T: Decodable>(as type: T.Type) throws -> T {
		guard case let .binary(byteBuffer) = self else {
			throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Expected binary message."))
		}

		do {
			return try Self.decoder.decode(type, from: byteBuffer)
		} catch {
			if let string = byteBuffer.getString(at: 0, length: byteBuffer.readableBytes) {
				print("Failed to decode: \(string)")
			}

			throw error
		}
	}
}
