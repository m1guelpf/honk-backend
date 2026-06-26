import Logging
import Foundation
import Dependencies
import DependenciesMacros
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@DependencyClient
struct PhoneNumberVerifier: Sendable {
	struct TwilioVerificationResponse: Decodable {
		enum Status: String, Decodable {
			case pending, approved, canceled, max_attempts_reached, deleted, failed, expired
		}

		var sid: String
		var to: String
		var status: Status
	}

	var sendVerificationCode: @Sendable (_ to: String) async throws -> TwilioVerificationResponse.Status
	var verify: @Sendable (_ phoneNumber: String, _ code: String) async throws -> TwilioVerificationResponse.Status
}

// MARK: - Implementation

extension PhoneNumberVerifier: DependencyKey {
	static let liveValue = PhoneNumberVerifier(
		sendVerificationCode: { phoneNumber in
			let response = try await makeTwilioRequest(path: "/Verifications", body: [
				"Channel": "sms",
				"To": phoneNumber,
			], as: TwilioVerificationResponse.self)

			return response.status
		},
		verify: { phoneNumber, code in
			let response = try await makeTwilioRequest(path: "/VerificationCheck", body: [
				"Code": code,
				"To": phoneNumber,
			], as: TwilioVerificationResponse.self)

			return response.status
		}
	)
}

// MARK: - Helpers

fileprivate let decoder = JSONDecoder()
fileprivate let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
fileprivate func makeTwilioRequest<T: Decodable>(path: String, body: [String: String], as _: T.Type) async throws -> T {
	@Dependency(\.config) var config
	let twilioServiceId = try config.requiredString(forKey: "twilio.serviceId")
	let credentials = try "\(config.requiredString(forKey: "twilio.accountId")):\(config.requiredString(forKey: "twilio.token"))"

	var request = URLRequest(url: URL(string: "https://verify.twilio.com/v2/Services/\(twilioServiceId)")!.appending(path: path))
	request.httpMethod = "POST"

	request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
	request.setValue("Basic \(Data(credentials.utf8).base64EncodedString())", forHTTPHeaderField: "Authorization")

	let encodedBody: String = body.map { key, value in
		let encodedKey = key.addingPercentEncoding(withAllowedCharacters: allowed)!
		let encodedValue = value.addingPercentEncoding(withAllowedCharacters: allowed)!
		return "\(encodedKey)=\(encodedValue)"
	}
	.joined(separator: "&")
	request.httpBody = Data(encodedBody.utf8)

	let (data, response) = try await URLSession.shared.data(for: request)

	guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
		throw URLError(.badServerResponse)
	}

	return try decoder.decode(T.self, from: data)
}

// MARK: - Dependencies

extension PhoneNumberVerifier {
	static let testValue = PhoneNumberVerifier()
}

extension DependencyValues {
	var phoneNumber: PhoneNumberVerifier {
		get { self[PhoneNumberVerifier.self] }
		set { self[PhoneNumberVerifier.self] = newValue }
	}
}
