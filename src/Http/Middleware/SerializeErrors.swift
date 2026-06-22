import Logging
import HTTPTypes
import Foundation
import Hummingbird

fileprivate let encoder = JSONEncoder()

public struct SerializeErrors<Context: RequestContext>: RouterMiddleware {
	public func handle(
		_ request: Request,
		context: Context,
		next: (Request, Context) async throws -> Response
	) async throws -> Response {
		do {
			return try await next(request, context)
		} catch let error as ErrorResponse {
			let response = try error.response(from: request, context: context)
			return Response(status: error.statusCode, headers: response.headers, body: response.body)
		} catch {
			return handleError(error, request: request, context: context)
		}
	}

	// MARK: - Error Handling

	/// Handle an error and convert it to a proper HTTP response
	private func handleError(
		_ error: Error,
		request: Request,
		context: Context
	) -> Response {
		let errorInfo = classifyError(error)
		logError(error, info: errorInfo, request: request, logger: context.logger)

		guard let errorBody = try? encoder.encode(ErrorResponse(errorInfo.status, code: errorInfo.code, message: errorInfo.description)) else {
			return Response(
				status: .internalServerError,
				headers: [.contentType: "application/json"],
				body: .init(byteBuffer: .init(string: #"{"status": 500,"code":"internal_server_error","description":"An unexpected error occurred"}"#))
			)
		}

		return Response(
			status: errorInfo.status,
			headers: [.contentType: "application/json"],
			body: .init(byteBuffer: .init(data: errorBody))
		)
	}

	/// Classify an error and determine response details
	private func classifyError(_ error: Error) -> ErrorInfo {
		switch error {
			case let error as HTTPError:
				return ErrorInfo(code: "malformedResponse", description: error.body, status: error.status)

			// Hummingbird errors
			case let error as HTTPResponseError:
				return handleHTTPResponseError(error)

			// Decoding errors
			case is DecodingError:
				return ErrorInfo(
					code: "invalid_request",
					description: "Invalid request format or parameters",
					status: .badRequest
				)

			// Encoding errors
			case is EncodingError:
				return ErrorInfo(
					code: "internal_server_error",
					description: "Failed to encode response",
					status: .internalServerError
				)

			// Cancellation errors
			case is CancellationError:
				return ErrorInfo(
					code: "request_cancelled",
					description: "Request was cancelled",
					status: .internalServerError
				)

			// Generic errors
			default:
				return ErrorInfo(
					code: "internal_server_error",
					description: "An unexpected error occurred: \(error.localizedDescription)",
					status: .internalServerError
				)
		}
	}

	/// Handle Hummingbird HTTPResponseError
	private func handleHTTPResponseError(_ error: HTTPResponseError) -> ErrorInfo {
		switch error.status {
			case .badRequest: ErrorInfo(
					code: "invalid_request",
					description: "Bad request",
					status: .badRequest
				)
			case .unauthorized: ErrorInfo(
					code: "unauthorized",
					description: "Authentication required or invalid credentials",
					status: .unauthorized
				)
			case .forbidden: ErrorInfo(
					code: "forbidden",
					description: "Access denied",
					status: .forbidden
				)
			case .notFound: ErrorInfo(
					code: "not_found",
					description: "Resource not found",
					status: .notFound
				)
			case .unprocessableContent: ErrorInfo(
					code: "unprocessable_entity",
					description: "Validation failed",
					status: .unprocessableContent
				)
			case .tooManyRequests: ErrorInfo(
					code: "rate_limit_exceeded",
					description: "Too many requests. Please try again later.",
					status: .tooManyRequests
				)
			default: ErrorInfo(
					code: "http_error",
					description: "HTTP error occurred",
					status: error.status
				)
		}
	}

	/// Log an error with appropriate severity
	private func logError(_ error: Error, info: ErrorInfo, request: Request, logger: Logger) {
		let metadata: Logger.Metadata = [
			"error_code": "\(info.code)",
			"http_method": "\(request.method)",
			"http_path": "\(request.uri.path)",
			"error_type": "\(type(of: error))",
			"http_status": "\(info.status.code)",
		]

		// Log based on status code
		switch info.status.code {
			case 400..<500: logger.warning("Client error", metadata: metadata)
			case 500..<600: logger.error("Server error", metadata: metadata.merging([
					"error_message": "\(error)",
				]) { $1 })
			default: logger.notice("Unexpected status code", metadata: metadata)
		}
	}
}

/// Error information for response
private struct ErrorInfo {
	let code: String
	let description: String?
	let status: HTTPResponse.Status
}
