import Foundation

fileprivate let honkDateStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
fileprivate let plainDateStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: false)

extension JSONEncoder.DateEncodingStrategy {
	static let honk = custom { date, encoder in
		var container = encoder.singleValueContainer()
		try container.encode(date.formatted(honkDateStyle))
	}
}

extension JSONDecoder.DateDecodingStrategy {
	static let honk = custom { decoder in
		let container = try decoder.singleValueContainer()
		let string = try container.decode(String.self)

		if let date = try? honkDateStyle.parse(string) { return date }
		if let date = try? plainDateStyle.parse(string) { return date }

		throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO-8601 date: \(string)")
	}
}
