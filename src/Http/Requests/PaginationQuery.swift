import Foundation
import Hummingbird

struct PaginationQuery: Equatable, Hashable, ResponseCodable, Sendable {
	var page: Int
	var perPage: Int

	var limit: Int { perPage }
	var offset: Int { (page - 1) * perPage }

	static let maxPerPage = 500
	static let defaultPerPage = 200

	init(page: Int = 1, perPage: Int = defaultPerPage) {
		self.page = max(page, 1)
		self.perPage = min(max(perPage, 1), Self.maxPerPage)
	}
}

// MARK: - Codable

extension PaginationQuery: Decodable {
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(
			page: container.decodeIfPresent(Int.self, forKey: .page) ?? 1,
			perPage: container.decodeIfPresent(Int.self, forKey: .perPage) ?? Self.defaultPerPage
		)
	}
}
