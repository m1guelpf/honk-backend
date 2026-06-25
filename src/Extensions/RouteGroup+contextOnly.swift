import Hummingbird
import HummingbirdRouter

public extension RouteGroup {
	init<ChildHandler: MiddlewareProtocol, ChildContext: ChildRequestContext & RouterRequestContext>(
		context: ChildContext.Type,
		@MiddlewareFixedTypeBuilder<Request, Response, ChildContext> builder: () -> ChildHandler
	) where ChildContext == ChildContext, Handler == ThrowingContextTransform<Context, ChildContext, ChildHandler> {
		self.init("", context: context, builder: builder)
	}

	init(@MiddlewareFixedTypeBuilder<Request, Response, Context> builder: () -> Handler) {
		self.init("", builder: builder)
	}
}
