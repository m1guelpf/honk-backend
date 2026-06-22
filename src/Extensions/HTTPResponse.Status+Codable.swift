import Hummingbird

extension HTTPResponse.Status: @retroactive Codable, @retroactive ResponseCodable {
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(code)
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()

		self = try .init(integerLiteral: container.decode(Int.self))
	}
}
