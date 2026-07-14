import Foundation

struct APIPresence: Equatable, Hashable, Codable, Sendable {
	var ping_id: Int
	var isOnline: Bool
	var callId: String?
	var appIsActive: Bool
	var isOnCall: Bool?
	var isInChat: String?
	var isOnScreen: String?
	var averagePingTimes: Double?
}
