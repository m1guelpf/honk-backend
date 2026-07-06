import Logging
import HTTPTypes
import Foundation
import Hummingbird
import HummingbirdCore

#if DEBUG && os(macOS)
@preconcurrency import Atlantis

typealias AtlantisRequest = Atlantis::Request
typealias AtlantisResponse = Atlantis::Response

public struct AtlantisMiddleware<Context: RequestContext>: RouterMiddleware {
	public func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
		var request = request
		let body = await body(&request, context: context)

		let capturedRequest = AtlantisRequest(
			url: "\(request.head.scheme ?? "http")://\(request.head.authority ?? "localhost")\(request.uri)",
			method: request.method.rawValue,
			headers: request.headers.map { .init(key: $0.name.canonicalName, value: $0.value) },
			body: body
		)

		var response = try await next(request, context)

		let capturedResponse = AtlantisResponse(
			statusCode: response.status.code,
			headers: response.headers.map { .init(key: $0.name.canonicalName, value: $0.value) }
		)

		response.body = .init(contentLength: response.body.contentLength) { [capturedRequest, body = response.body] writer in
			try await body.write(SendsAndLogsResponse(parentWriter: writer, onFinish: { body in
				Atlantis.add(
					request: capturedRequest,
					response: capturedResponse,
					responseBody: body
				)
			}))
		}

		return response
	}

	func body(_ request: inout Request, context: Context) async -> Data? {
		do {
			let buffer = try await request.collectBody(upTo: context.maxUploadSize)
			return buffer.getData(at: buffer.readerIndex, length: buffer.readableBytes)
		} catch {
			context.logger.error("Failed to decode request body for logging: \(error)")
			return nil
		}
	}
}

struct SendsAndLogsResponse: ResponseBodyWriter {
	var parentWriter: any ResponseBodyWriter
	var onFinish: (Data) -> Void

	private var data = Data()

	mutating func write(_ buffer: ByteBuffer) async throws {
		var bufferCopy = buffer
		if let data = bufferCopy.readData(length: buffer.readableBytes) {
			self.data += data
		}

		try await parentWriter.write(buffer)
	}

	consuming func finish(_ trailingHeaders: HTTPFields?) async throws {
		onFinish(data)
		try await parentWriter.finish(trailingHeaders)
	}
}
#endif
