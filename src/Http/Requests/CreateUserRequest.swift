import Foundation
import Hummingbird

struct CreateUserRequest: Equatable, Hashable, Codable, ResponseCodable, Sendable {
	var uid: String
	var name: String
	var username: String
	var starSign: User.StarSign?
	var location: User.Location?
	var dateOfBirth: String // ddmmyyyy
	var gender: User.Gender?
	var pronouns: [String]?
	var interests: [String]
}
