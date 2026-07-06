import Foundation
import SQLiteData

@Table
struct Block: Identifiable {
	@Selection struct ID: Equatable, Hashable {
		var blockerId: User.ID
		var blockedId: User.ID
	}

	var id: ID
	var source: String
	var createdAt: Date
}

extension Block.TableColumns {
	func isFrom(_ blockerId: some QueryExpression<User.ID>, to blockedId: some QueryExpression<User.ID>) -> some QueryExpression<Bool> {
		id.blockerId.eq(blockerId) && id.blockedId.eq(blockedId)
	}

	func isBetween(_ firstUserId: some QueryExpression<User.ID>, and secondUserId: some QueryExpression<User.ID>) -> some QueryExpression<Bool> {
		isFrom(firstUserId, to: secondUserId) || isFrom(secondUserId, to: firstUserId)
	}
}
