import Hummingbird
@preconcurrency import SnapshotTesting
import HummingbirdTesting

public extension Snapshotting where Value == TestResponse, Format == String {
	static let http = Snapshotting<TestResponse, String>(pathExtension: "curl.txt", diffing: .lines) { testResponse in
		let contentLength = testResponse.headers[.contentLength].flatMap { Int($0) } ?? 0

		var components: [String?] = [testResponse.status.description]
		components += testResponse.headers.map { f in f.description }
		if contentLength > 0 {
			var body = testResponse.body
			if let bodyString = body.readString(length: testResponse.body.readableBytes, encoding: .utf8), !bodyString.isEmpty {
				components.append("")
				components.append(bodyString)
			}
		}

		return components.compactMap { $0 }.joined(separator: "\n")
	}
}
