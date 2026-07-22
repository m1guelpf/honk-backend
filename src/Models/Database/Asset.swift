import Foundation
import SQLiteData

@Table
struct Asset: Identifiable {
	enum Kind: String, Equatable, Hashable, Codable, QueryBindable, Sendable {
		case image, audio, video, imagePreview
	}

	struct Parameters: Equatable, Hashable, Codable, Sendable {
		var availability: String? // "loading", "notAvailable", "available"
		var caption: String
		var assetType: String // imagePreview, image, audio, video – assetDataUpdate?
		var contentID: UUID
		var blurHash: String?
		var originalWidth: Int?
		var originalHeight: Int?
		var width: Int?
		var height: Int?
		var format: String? // "blurhash"
		var duration: Double?
		var waveformRepresentation: [Double]?
	}

	var id: String
	var ownerId: User.ID
	var kind: Kind
	var storageRef: String
	var blurHash: String?
	@Column(as: Asset.Parameters?.JSONRepresentation.self)
	var parameters: Parameters?
	var thumbnails: String?
	var includesCaption: Bool
	var metadata: String?
	var createdAt: Date
}
