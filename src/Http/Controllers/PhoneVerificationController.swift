import Foundation
import SQLiteData
import Hummingbird
import Dependencies
import HummingbirdRouter

struct PhoneVerificationController: RouterController {
	var body: some RouterMiddleware<AuthContext> {
		Post("validate/phone", handler: validatePhoneNumber)
		Post("validate/phone/confirm", handler: confirmPhoneNumber)
	}

	@Dependency(\.date.now) var now
	@Dependency(\.defaultDatabase) var database
	@Dependency(\.phoneNumber) var phoneVerifier

	func validatePhoneNumber(_ request: Request, context: AuthContext) async throws -> ServerResponse {
		let request = try await request.decode(as: ValidatePhoneRequest.self, context: context)
		// for simplicity, we won't check if the phone number is valid or not. If we ever do this, return 422

		let phoneNumber = request.number.replacingOccurrences(of: " ", with: "")

		guard let phoneNumberTaken = try await database.read({ db in
			try Values(User.where { $0.phoneNumber.eq(phoneNumber) }.exists()).fetchOne(db)
		}), !phoneNumberTaken else { throw HTTPError(.conflict, message: "That phone number is already in use.") }

		let result = try await phoneVerifier.sendVerificationCode(to: phoneNumber)

		switch result {
			case .pending: return ServerResponse(.ok, message: "Phone number is valid.")
			case .failed: throw HTTPError(.unprocessableContent, message: "Failed to send verification code.")
			case .max_attempts_reached: throw HTTPError(.tooManyRequests, message: "Too many attempts to send verification code.")
			default: throw HTTPError(.internalServerError, message: "Unexpected result from sending verification code.")
		}
	}

	func confirmPhoneNumber(_ request: Request, context: AuthContext) async throws -> PhoneNumberVerifiedResponse {
		let request = try await request.decode(as: ConfirmPhoneRequest.self, context: context)

		let phoneNumber = request.number.replacingOccurrences(of: " ", with: "")

		let result = try await phoneVerifier.verify(phoneNumber: phoneNumber, code: request.code)

		guard case .approved = result else {
			switch result {
				case .pending: throw HTTPError(.unprocessableContent, message: "Verification code is incorrect.")
				case .failed: throw HTTPError(.unprocessableContent, message: "Failed to send verification code.")
				case .max_attempts_reached: throw HTTPError(.tooManyRequests, message: "Too many attempts to send verification code.")
				default: throw HTTPError(.internalServerError, message: "Unexpected result from sending verification code.")
			}
		}

		try await database.write { db in
			try User.find(context.user.id).update { $0.contactHash = #bind(phoneNumber.contactHash) }.execute(db)
		}

		return PhoneNumberVerifiedResponse(contactHash: phoneNumber.contactHash)
	}
}
