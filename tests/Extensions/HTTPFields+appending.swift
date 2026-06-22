import Hummingbird

extension HTTPFields {
	func appending(_ other: HTTPFields.Element) -> HTTPFields {
		var copy = self
		copy.append(other)
		return copy
	}
}
