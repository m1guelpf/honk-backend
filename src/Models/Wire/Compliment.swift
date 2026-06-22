import Foundation
import Hummingbird

// TODO: Figure out schema
struct Compliment: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var id: String
	var color: Color
	var backgroundColor: Color?
}
