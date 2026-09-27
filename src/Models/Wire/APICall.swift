import Foundation

struct APICall: Equatable, Hashable, Codable, Sendable {
	var _id: UUID
	var callId: UUID
	var status: String
	var userId: User.ID
	var users: [User.ID]
	var createdAt: Date
	var updatedAt: Date
	var didInitiateCall: Bool

	init(from call: Call, viewedBy userID: User.ID) {
		_id = call.id
		callId = call.id
		userId = call.callerId
		createdAt = call.createdAt
		updatedAt = call.updatedAt
		status = call.state.rawValue
		users = [call.callerId, call.recipientId]
		didInitiateCall = call.callerId == userID
	}
}
