import Hummingbird
import HummingbirdRouter

struct AppController: RouterController {
	var body: some RouterMiddleware<Context> {
		RouteGroup("app") {
			Get("init", handler: self.`init`)
			Get("versions", handler: self.versions)
		}
	}

	func `init`(_: Request, context _: Context) -> InitializationResponse {
		return InitializationResponse()
	}

	func versions(_: Request, context _: Context) -> AppVersions {
		return AppVersions(
			latestVersionInfo: .init(versionNumber: "1.7.3", buildNumber: "20220125030111", requiredOSVersion: "17.0"),
			requiredVersionInfo: .init(versionNumber: "1.7.3", buildNumber: "20220125030111", requiredOSVersion: "17.0")
		)
	}
}
