import HTTPTypes
import Foundation

extension HTTPFields {
	var boundary: String? { self[.contentType].flatMap { parameter("boundary", in: $0) } }
	var filename: String? { self[.contentDisposition].flatMap { parameter("filename", in: $0) } }
	var contentDispositionName: String? { self[.contentDisposition].flatMap { parameter("name", in: $0) } }

	private func parameter(_ key: String, in header: String) -> String? {
		for component in header.split(separator: ";") {
			let trimmed = component.trimmingCharacters(in: .whitespaces)
			guard trimmed.hasPrefix("\(key)=") else { continue }
			return trimmed.dropFirst(key.count + 1).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
		}

		return nil
	}
}
