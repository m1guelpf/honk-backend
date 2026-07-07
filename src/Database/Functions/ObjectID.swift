import Foundation
import SQLiteData

@DatabaseFunction(isDeterministic: false)
func objectID() -> String {
	var data = Data()

	// 4-byte timestamp (big-endian)
	@Dependency(\.date.now) var now
	var timestamp = UInt32(now.timeIntervalSince1970).bigEndian
	withUnsafeBytes(of: &timestamp) {
		data.append(contentsOf: $0)
	}

	// 3 random bytes
	var random1 = UInt32.random(in: .min ... .max).bigEndian
	withUnsafeBytes(of: &random1) {
		data.append(contentsOf: $0.prefix(3))
	}

	// 2-byte process ID (big-endian)
	var pid = UInt32(ProcessInfo.processInfo.processIdentifier).bigEndian
	withUnsafeBytes(of: &pid) {
		data.append(contentsOf: $0.prefix(2))
	}

	// 3 random bytes
	var random2 = UInt32.random(in: .min ... .max).bigEndian
	withUnsafeBytes(of: &random2) {
		data.append(contentsOf: $0.prefix(3))
	}

	return data.map { String(format: "%02x", $0) }.joined()
}
