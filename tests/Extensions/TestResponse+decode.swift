import Foundation
@testable import HonkBackend
import IssueReporting
import HummingbirdTesting

extension TestResponse {
	static let decoder = {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .honk
		return decoder
	}()

	func decode<T: Decodable>(as type: T.Type) throws -> T {
		do {
			return try Self.decoder.decode(type, from: body)
		} catch {
			if let string = body.getString(at: 0, length: body.readableBytes) {
				print("Failed to decode: \(string)")
			}

			throw error
		}
	}
}
