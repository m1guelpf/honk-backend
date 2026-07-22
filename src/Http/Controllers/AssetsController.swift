import NIOCore
import FileType
import HTTPTypes
import Foundation
import SQLiteData
import Hummingbird
import Dependencies
import MultipartKit
import HummingbirdRouter

struct AssetsController: RouterController {
	var body: some RouterMiddleware<AuthContext> {
		Post("aws", handler: upload)
		Get("aws/:assetId", handler: download)
		Delete("aws/:assetId", handler: delete)
	}

	@Dependency(\.date.now) var now
	@Dependency(\.storage) var storage
	@Dependency(\.defaultDatabase) var database

	func upload(_ request: Request, context: AuthContext) async throws -> [String: String] {
		guard let boundary = request.headers.boundary else {
			throw HTTPError(.unsupportedMediaType, message: "Expected multipart/form-data")
		}

		var contentID: String?
		var bytes = ByteBuffer()

		let sections = StreamingMultipartParserAsyncSequence(boundary: boundary, buffer: request.body.map { $0.readableBytesView.drop(while: { $0 == 0x0D || $0 == 0x0A }) })
		for try await section in sections {
			switch section {
				case .boundary: break

				case let .headerFields(fields):
					guard fields.contentDispositionName == "asset", let filename = fields.filename else { continue }
					contentID = filename

				case let .bodyChunk(chunk):
					guard contentID != nil else { continue }
					guard bytes.readableBytes + chunk.count <= context.maxUploadSize else {
						throw HTTPError(.contentTooLarge, message: "Asset exceeds \(context.maxUploadSize) bytes")
					}

					bytes.writeBytes(chunk)
			}
		}

		guard let contentID else { throw HTTPError(.badRequest, message: "Missing `asset` part") }
		let contentType = FileType.detect(in: bytes.getData(at: 0, length: 20) ?? Data())

		_ = try await storage.upload(bytes, "assets/\(contentID)", contentType?.mime ?? "application/octet-stream")

		return [:]
	}

	func download(_: Request, context: AuthContext) async throws -> Response {
		let assetId = try context.parameters.require("assetId")

		let bytes = try await storage.download("assets/\(assetId)")
		let contentType = FileType.detect(in: bytes)

		return Response(
			status: .ok,
			headers: [.contentType: contentType?.mime ?? "application/octet-stream"],
			body: .init(byteBuffer: ByteBuffer(data: bytes))
		)
	}

	func delete(_: Request, context: AuthContext) async throws -> [String: String] {
		let assetId = try context.parameters.require("assetId")
		let me = context.user

		guard let assetPath = try await database.write({ db in
			try Asset.where { $0.id.eq(assetId) && $0.ownerId.eq(me.id) }.delete().returning(\.storageRef).fetchOne(db)
		}) else { throw HTTPError(.notFound, message: "Asset not found") }

		try await storage.delete(assetPath)

		return [:]
	}
}
