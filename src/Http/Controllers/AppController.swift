import Hummingbird
import HummingbirdRouter

struct AppController: RouterController {
	var body: some RouterMiddleware<Context> {
		RouteGroup("app") {
			Get("init", handler: self.`init`)
		}
	}

	func `init`(_: Request, context _: Context) -> InitializationResponse {
		return InitializationResponse()
	}
}
