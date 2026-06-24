import Testing
@testable import HonkBackend
import HummingbirdTesting
import InlineSnapshotTesting
import SnapshotTestingCustomDump

extension Tests {
	@Suite struct AppController {}
}

extension Tests.AppController {
	@Test func `init`() async throws {
		let app = configure()

		try await app.test(.router) { client in
			try await client.get("/app/init") { response in
				#expect(response.status == .ok)
				try assertInlineSnapshot(of: response.decode(as: InitializationResponse.self), as: .customDump) {
					"""
					InitializationResponse(
					  currentVersion: "1.7.3",
					  currentBuild: "20220125030111",
					  minimumVersion: "1.0.0",
					  requiredAppVersion: nil,
					  themes: [],
					  doubleTapEmoji: "❤️",
					  bios: [
					    [0]: InitializationResponse.RawBioDescription(
					      id: "blue",
					      color: Color(
					        red: 0.36,
					        green: 0.61,
					        blue: 0.96,
					        alpha: 1.0
					      ),
					      colorDark: Color(
					        red: 0.2,
					        green: 0.4,
					        blue: 0.75,
					        alpha: 1.0
					      )
					    ),
					    [1]: InitializationResponse.RawBioDescription(
					      id: "yellow",
					      color: Color(
					        red: 0.99,
					        green: 0.83,
					        blue: 0.3,
					        alpha: 1.0
					      ),
					      colorDark: Color(
					        red: 0.78,
					        green: 0.62,
					        blue: 0.12,
					        alpha: 1.0
					      )
					    ),
					    [2]: InitializationResponse.RawBioDescription(
					      id: "green",
					      color: Color(
					        red: 0.4,
					        green: 0.8,
					        blue: 0.45,
					        alpha: 1.0
					      ),
					      colorDark: Color(
					        red: 0.22,
					        green: 0.55,
					        blue: 0.28,
					        alpha: 1.0
					      )
					    ),
					    [3]: InitializationResponse.RawBioDescription(
					      id: "pink",
					      color: Color(
					        red: 0.96,
					        green: 0.55,
					        blue: 0.72,
					        alpha: 1.0
					      ),
					      colorDark: Color(
					        red: 0.74,
					        green: 0.35,
					        blue: 0.52,
					        alpha: 1.0
					      )
					    ),
					    [4]: InitializationResponse.RawBioDescription(
					      id: "peach",
					      color: Color(
					        red: 0.99,
					        green: 0.7,
					        blue: 0.55,
					        alpha: 1.0
					      ),
					      colorDark: Color(
					        red: 0.78,
					        green: 0.5,
					        blue: 0.36,
					        alpha: 1.0
					      )
					    ),
					    [5]: InitializationResponse.RawBioDescription(
					      id: "grey",
					      color: Color(
					        red: 0.6,
					        green: 0.62,
					        blue: 0.66,
					        alpha: 1.0
					      ),
					      colorDark: Color(
					        red: 0.38,
					        green: 0.4,
					        blue: 0.44,
					        alpha: 1.0
					      )
					    )
					  ],
					  features: nil,
					  popularInterests: nil,
					  categories: nil,
					  compliments: nil,
					  mostRecentInterests: nil,
					  disableDiffEndpoints: false,
					  message: nil,
					  sunsetMessage: nil
					)
					"""
				}
			}
		}
	}
}
