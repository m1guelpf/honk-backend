import Crypto
import Foundation

extension String {
	var contactHash: String {
		let digest = SHA512.hash(data: Data(utf8))

		var hex = ""
		hex.reserveCapacity(128)

		for byte in digest {
			hex += String(format: "%02x", byte)
		}

		return hex
	}
}
