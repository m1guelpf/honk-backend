import Foundation
import Hummingbird

struct APITimestamp: Equatable, Hashable, ResponseCodable, Sendable {
	var milliseconds: Int
}

extension APITimestamp {
	init(_ date: Date) {
		milliseconds = Int(date.timeIntervalSince1970 * 1000)
	}
}

// MARK: - Codable

extension APITimestamp: Codable {
	func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(milliseconds)
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		milliseconds = try container.decode(Int.self)
	}
}
