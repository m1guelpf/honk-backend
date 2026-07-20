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
	static let maxAssetBytes = 25 * 1024 * 1024

	var body: some RouterMiddleware<AuthContext> {
		Post("aws", handler: upload)
		Get("aws/:assetId", handler: download)
		Delete("aws/:assetId", handler: delete)
	}

	@Dependency(\.date.now) var now
	@Dependency(\.storage) var storage
	@Dependency(\.defaultDatabase) var database

	func upload(_ request: Request, context _: AuthContext) async throws -> [String: String] {
		guard let boundary = request.headers.boundary else {
			throw HTTPError(.unsupportedMediaType, message: "Expected multipart/form-data")
		}

		let whole = try await request.body.collect(upTo: Self.maxAssetBytes)
		let body = [UInt8](whole.readableBytesView.drop(while: { $0 == 0x0D || $0 == 0x0A }))

		let sections = StreamingMultipartParserAsyncSequence(boundary: boundary, buffer: AsyncStream<[UInt8]> {
			$0.yield(body)
			$0.finish()
		})

		var contentID: String?
		var bytes = ByteBuffer()

		for try await section in sections {
			switch section {
				case let .headerFields(fields):
					guard fields.contentDispositionName == "asset", let filename = fields.filename else { continue }
					contentID = filename

				case let .bodyChunk(chunk):
					guard contentID != nil else { continue }
					bytes.writeBytes(chunk)
					guard bytes.readableBytes <= Self.maxAssetBytes else {
						throw HTTPError(.contentTooLarge, message: "Asset exceeds \(Self.maxAssetBytes) bytes")
					}

				case .boundary:
					break
			}
		}

		guard let contentID else { throw HTTPError(.badRequest, message: "Missing `asset` part") }
		let contentType = FileType.detect(in: bytes.getData(at: 0, length: 20) ?? Data())

		_ = try await storage.upload(bytes, "assets/\(contentID)", contentType?.mime ?? "application/octet-stream")

		return [:]
	}

	func download(_: Request, context: AuthContext) async throws -> Response {
		let assetId = try context.parameters.require("assetId")

		guard let asset = try await database.read({ db in try Asset.find(assetId).fetchOne(db) }) else {
			throw HTTPError(.notFound)
		}

		let bytes = try await storage.download(asset.storageRef)
		let contentType = FileType.detect(in: bytes)

		return Response(
			status: .ok,
			headers: [.contentType: contentType?.mime ?? "application/octet-stream"],
			body: .init(byteBuffer: ByteBuffer(data: bytes))
		)
	}

	func delete(_: Request, context: AuthContext) async throws -> [String: String] {
		let assetId = try context.parameters.require("assetId")

		try await storage.delete("assets/\(assetId)")

		// TODO: Remove from database

		return [:]
	}
}
