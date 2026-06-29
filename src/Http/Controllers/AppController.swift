import Hummingbird
import HummingbirdRouter

struct AppController: RouterController {
	var body: some RouterMiddleware<Context> {
		RouteGroup("app") {
			Get("init", handler: self.`init`)
			Get("versions", handler: self.versions)
		}

		Get("users/avatars", handler: avatars)
	}

	func `init`(_: Request, context _: Context) -> InitializationResponse {
		return InitializationResponse()
	}

	func versions(_: Request, context _: Context) -> AppVersionsResponse {
		return AppVersionsResponse(versions: ["1.7.3"])
	}

	func avatars(_: Request, context _: Context) -> DefaultAvatarsResponse {
		return DefaultAvatarsResponse(avatars: ["https://firebasestorage.googleapis.com/v0/b/honkreloaded.firebasestorage.app/o/system%2Fdefault-avatar.png?alt=media"])
	}
}
