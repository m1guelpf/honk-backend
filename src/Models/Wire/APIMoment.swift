import Foundation
import Hummingbird

struct APIMoment: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	struct Thumbnails: Equatable, Hashable, Codable, Sendable {
		var small: String?
		var large: String?
	}

	struct Metadata: Equatable, Hashable, Codable, Sendable {
		// TODO: what goes here?
	}

	var contentID: String
	var createdAt: Date
	var userId: String
	var ownerId: String?
	var type: String
	var includesCaption: Bool?
	var thumbnails: Thumbnails?
	var metadata: Metadata
}

extension APIMoment {
	init(from moment: Moment) {
		contentID = moment.id // TODO: is this `id` or `assetId`
		createdAt = moment.createdAt
		userId = moment.createdById // TODO: is this the right user?
		ownerId = moment.createdById
		type = "" // TODO: what goes here?
		includesCaption = moment.includesCaption
		thumbnails = Thumbnails() // TODO: where do we get this from?
		metadata = Metadata() // TODO: populate Moment.metadata
	}
}
