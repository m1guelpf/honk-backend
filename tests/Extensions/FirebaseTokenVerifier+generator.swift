import JWTKit
import Foundation
@testable import HonkBackend
import Dependencies

extension FirebaseTokenVerifier {
	func generate(userID: String) async throws -> String {
		@Dependency(\.date.now) var now
		@Dependency(\.config) var config
		let applicationIdentifier = try config.requiredString(forKey: "firebase.appIdentifier")

		return try await keys().sign(FirebaseAuthIdentityToken(
			issuer: IssuerClaim(value: "https://securetoken.google.com/\(applicationIdentifier)"),
			subject: SubjectClaim(value: userID),
			audience: AudienceClaim(value: applicationIdentifier),
			issuedAt: IssuedAtClaim(value: now),
			expires: ExpirationClaim(value: Date().adding(.minutes(10))),
			userID: userID
		))
	}
}
