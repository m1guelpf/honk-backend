import Crypto
import Foundation
import Hummingbird
import Dependencies
import Configuration

struct Agora: Sendable {
	@Dependency(\.date.now) private var now
	@Dependency(\.config) private var config

	func token(for channel: UUID, expiresAt: Date) throws -> String {
		let appID = try config.requiredString(forKey: "agora.appId")
		let certificate = try config.requiredString(forKey: "agora.appCertificate", isSecret: true)
		guard [appID, certificate].allSatisfy({ $0.utf8.count == 32 && $0.allSatisfy(\.isHexDigit) }) else {
			throw HTTPError(.serviceUnavailable, message: "Calls are not configured.")
		}

		var message = Data()
		let expiry = UInt32(expiresAt.timeIntervalSince1970)
		message.appendInteger(UInt32.random(in: 1 ... 99_999_999))
		message.appendInteger(UInt32(now.adding(.days(1)).timeIntervalSince1970))
		message.appendInteger(UInt16(4))
		for privilege in UInt16(1) ... 4 {
			message.appendInteger(privilege)
			message.appendInteger(expiry)
		}

		let signed = Data(appID.utf8) + Data(channel.uuidString.utf8) + message
		let signature = HMAC<SHA256>.authenticationCode(for: signed, using: SymmetricKey(data: Data(certificate.utf8)))
		var content = Data()
		content.appendBytes(Data(signature))
		content.appendInteger(Self.crc32(Data(channel.uuidString.utf8)))
		content.appendInteger(UInt32(0))
		content.appendBytes(message)
		return "006" + appID + content.base64EncodedString()
	}

	private static func crc32(_ data: Data) -> UInt32 {
		var crc = UInt32.max
		for byte in data {
			crc ^= UInt32(byte)
			for _ in 0 ..< 8 {
				crc = crc & 1 == 1 ? (crc >> 1) ^ 0xEDB8_8320 : crc >> 1
			}
		}
		return ~crc
	}
}

// MARK: - Dependency

extension Agora: DependencyKey {
	static let liveValue = Agora()
	static var testValue: Agora { Agora() }
}

extension DependencyValues {
	var agora: Agora {
		get { self[Agora.self] }
		set { self[Agora.self] = newValue }
	}
}
