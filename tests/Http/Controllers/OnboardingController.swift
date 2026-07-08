import Testing
import Foundation
@testable import HonkBackend
import Dependencies
import InlineSnapshotTesting
import DependenciesTestSupport

extension Tests {
	@Suite(.dependencies { try $0.bootstrapDatabase() })
	struct OnboardingController {}
}

// MARK: - Username Reservation Tests

extension Tests.OnboardingController {
	@Test func canReserveValidUsername() async throws {
		let app = configure()

		@Dependency(\.authTokens) var authTokens
		let (token, _) = try await authTokens.generate(for: "test-user")

		try await app.test(.router) { client in
			try await client.post("/reserve", auth: .bearer(token), body: ReserveRequest(username: "m1guelpf")) { response in
				#expect(response.status == .ok)
				try assertInlineSnapshot(of: response.decode(as: MessageResponse.self), as: .customDump) {
					"""
					MessageResponse(message: "Username is available.")
					"""
				}
			}
		}
	}

	@Test func cannotReserveUsernameWithoutValidToken() async throws {
		let app = configure()

		try await app.test(.router) { client in
			try await client.post("/reserve", body: ReserveRequest(username: "m1guelpf")) { response in
				#expect(response.status == .unauthorized)
				try assertInlineSnapshot(of: response.decode(as: ErrorResponse.self), as: .customDump) {
					"""
					ErrorResponse(
					  statusCode: HTTPResponse.Status(
					    code: 401,
					    reasonPhrase: ""
					  ),
					  errorCode: "malformedResponse",
					  message: "Failed to authenticate"
					)
					"""
				}
			}
		}
	}

	@Test(arguments: [
		"___________", "a", "morethansixteencharactername", "contains-hyphen", "contains_underscore",
	]) func cannotReserveInvalidUsername(invalidUsername: String) async throws {
		let app = configure()

		@Dependency(\.authTokens) var authTokens
		let (token, _) = try await authTokens.generate(for: "test-user")

		try await app.test(.router) { client in
			try await client.post("/reserve", auth: .bearer(token), body: ReserveRequest(username: invalidUsername)) { response in
				#expect(response.status == .unprocessableContent)
				try assertInlineSnapshot(of: response.decode(as: ErrorResponse.self), as: .customDump) {
					#"""
					ErrorResponse(
					  statusCode: HTTPResponse.Status(
					    code: 422,
					    reasonPhrase: ""
					  ),
					  errorCode: "usernameInvalid",
					  message: "That username isn\'t valid."
					)
					"""#
				}
			}
		}
	}

	@Test func cannotReserveTakenUsername() async throws {
		let app = configure()

		@Dependency(\.authTokens) var authTokens
		let (token, _) = try await authTokens.generate(for: "test-user")

		@Dependency(\.defaultDatabase) var database
		try await database.write { db in
			try User.insert { User(id: "userid", username: "takenusername", name: "Taken User", avatarUrl: URL(string: "https://example.com")!, birthday: Date(), lastOnlineAt: Date(), createdAt: Date(), updatedAt: Date()) }.execute(db)
		}

		try await app.test(.router) { client in
			try await client.post("/reserve", auth: .bearer(token), body: ReserveRequest(username: "takenusername")) { response in
				#expect(response.status == .conflict)
				try assertInlineSnapshot(of: response.decode(as: ErrorResponse.self), as: .customDump) {
					"""
					ErrorResponse(
					  statusCode: HTTPResponse.Status(
					    code: 409,
					    reasonPhrase: ""
					  ),
					  errorCode: "usernameTaken",
					  message: "That username is taken."
					)
					"""
				}
			}
		}
	}
}

// MARK: - Account Creation Tests

extension Tests.OnboardingController {
	@Test func canCreateAccount() async throws {
		let app = configure()

		@Dependency(\.authTokens) var authTokens
		let (token, tokenPayload) = try await authTokens.generate(for: "test-user")

		let request = CreateUserRequest(
			uid: "someuid",
			name: "Miguel Piedrafita",
			username: "m1guelpf",
			starSign: "pisces",
			location: .init(city: "Lisbon", subCountry: "Lisbon", country: "Portugal"),
			dateOfBirth: "19032002",
			gender: .man,
			pronouns: ["he", "him"],
			interests: ["73cc0a04-5c32-498b-bf4b-8673d811ac5c"]
		)

		try await app.test(.router) { client in
			try await client.post("/users", auth: .bearer(token), body: request) { response in
				#expect(response.status == .ok)

				let response = try response.decode(as: AuthenticationResponse.self)
				#expect(response.token == token)
				#expect(response.expiresAt.is(tokenPayload.exp.value))
				assertInlineSnapshot(of: response.user, as: .customDump) {
					"""
					APIUserInfo(
					  _id: "someuid",
					  firebaseAuthId: "test-user",
					  name: "Miguel Piedrafita",
					  username: "m1guelpf",
					  avatarURL: URL(https://firebasestorage.googleapis.com/v0/b/honkreloaded.firebasestorage.app/o/system%2Fdefault-avatar.png?alt=media),
					  avatarBlurHash: nil,
					  createdAt: Date(2026-03-19T12:00:00.000Z),
					  birthday: Date(2002-03-19T12:00:00.000Z),
					  isNotificationsEnabled: true,
					  isVerified: false,
					  allowFriendRequests: true,
					  showInSuggested: true,
					  preferredEmojiSkinTone: .default,
					  reactionEmojis: [],
					  quickReaction: "",
					  bio: "",
					  bioColor: nil,
					  status: "",
					  statusEmoji: "",
					  statusTimeout: nil,
					  statusClearValue: nil,
					  stats: User.Stats(
					    totalHonksSent: 0,
					    totalImagesSent: 0,
					    totalCharactersSent: 0
					  ),
					  supportCode: "",
					  invited: 0,
					  globalMagicWords: [],
					  contactHash: nil,
					  meetNotifyEnabled: nil,
					  meetInterests: [],
					  meetGender: nil,
					  meetNotificationsEnabled: nil,
					  pronouns: nil,
					  gender: nil,
					  meetLocation: nil,
					  starSign: nil,
					  matchRating: nil,
					  allowMatchAudio: true,
					  allowMatchImages: true,
					  allowMatchVideos: true,
					  discoverDisabled: false,
					  hasAgreedToMeetTerms: false,
					  hasReducedHonks: false,
					  teamNotificationsEnabled: true,
					  streakNotificationsDisabled: false,
					  hasReducedNotifications: false,
					  topPicksNotificationEnabled: true,
					  feelingLuckyNotificationEnabled: true,
					  badgeCount: 0,
					  compliments: [:],
					  needsConfirmDOB: false,
					  shouldForceReloadFriends: true,
					  honkButton: .classic
					)
					"""
				}
			}
		}
	}
}
