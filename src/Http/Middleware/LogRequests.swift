import Logging
import HTTPTypes
import Hummingbird

public struct LogRequests<Context: RequestContext>: RouterMiddleware {
	let logLevel: Logger.Level
	let includeHeaders: HeaderFilter
	let redactHeaders: [HTTPField.Name]

	public init(_ logLevel: Logger.Level, includeHeaders: HeaderFilter = .none, redactHeaders: [HTTPField.Name] = []) {
		self.logLevel = logLevel
		self.includeHeaders = includeHeaders
		self.redactHeaders = switch includeHeaders.value {
			case .none: []
			case let .some(included): redactHeaders.filter { header in included.contains(header) }
			case let .all(exceptions): redactHeaders.filter { header in !exceptions.contains(header) }
		}
	}

	public func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
		var request = request
		let body = await body(&request, context: context)

		context.logger.log(level: logLevel, "Request", metadata: [
			"body": .stringConvertible(body ?? ""),
			"path": .stringConvertible(request.uri),
			"method": .string(request.method.rawValue),
			"headers": .stringConvertible(headers(request.headers)),
		])

		return try await next(request, context)
	}

	func body(_ request: inout Request, context: Context) async -> String? {
		do {
			let buffer = try await request.collectBody(upTo: context.maxUploadSize)
			return buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes)
		} catch {
			context.logger.error("Failed to decode request body for logging: \(error)")
			return nil
		}
	}

	func headers(_ headers: HTTPFields) -> [String: String] {
		switch includeHeaders.value {
			case .none: return [:]
			case let .all(except):
				let headers = headers.compactMap { entry -> (key: String, value: String)? in
					if except.contains(where: { entry.name == $0 }) { return nil }

					return if self.redactHeaders.contains(entry.name) { (key: entry.name.canonicalName, value: "***") }
					else { (key: entry.name.canonicalName, value: entry.value) }
				}

				return .init(headers) { "\($0), \($1)" }
			case let .some(filter):
				let headers = filter.compactMap { entry -> (key: String, value: String)? in
					guard let value = headers[entry] else { return nil }

					return if self.redactHeaders.contains(entry) { (key: entry.canonicalName, value: "***") }
					else { (key: entry.canonicalName, value: value) }
				}

				return .init(headers) { "\($0), \($1)" }
		}
	}
}

// MARK: - HeaderFilter

public extension LogRequests {
	struct HeaderFilter: Sendable {
		fileprivate enum _Internal: Sendable {
			case none
			case some([HTTPField.Name])
			case all(except: [HTTPField.Name])
		}

		fileprivate let value: _Internal
		fileprivate init(_ value: _Internal) {
			self.value = value
		}

		/// Don't output any headers
		public static var none: Self { .init(.none) }

		/// Output all headers, except the ones indicated
		public static func all(except: [HTTPField.Name] = []) -> Self {
			.init(.all(except: except))
		}

		/// Output only these headers
		public static func some(_ headers: [HTTPField.Name]) -> Self {
			.init(.some(headers))
		}
	}
}

extension LogRequests.HeaderFilter: ExpressibleByArrayLiteral {
	public typealias ArrayLiteralElement = HTTPField.Name

	public init(arrayLiteral elements: ArrayLiteralElement...) {
		value = .some(elements)
	}
}
