import Foundation

extension Data {
	mutating func appendInteger(_ value: some FixedWidthInteger) {
		var value = value.littleEndian
		Swift.withUnsafeBytes(of: &value) { append(contentsOf: $0) }
	}

	mutating func appendBytes(_ data: Data) {
		appendInteger(UInt16(data.count))
		append(data)
	}
}
