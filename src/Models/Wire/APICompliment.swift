import Foundation
import Hummingbird

// TODO: Figure out schema
struct APICompliment: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var id: String
	var color: APIColor
	var backgroundColor: APIColor?
}
