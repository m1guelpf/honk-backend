import SQLiteData
import Foundation

@Table
struct Moment: Identifiable {
	var id: String
	var friendshipId: Friendship.ID
	var assetId: Asset.ID
	var createdById: User.ID
	var includesCaption: Bool
	var metadata: String?
	var createdAt: Date
}
