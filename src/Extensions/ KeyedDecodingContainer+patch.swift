import Foundation

extension KeyedDecodingContainer {
	func decodePatchOptional<T: Decodable>(_: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T?? {
		do {
			return try .some(decode(T.self, forKey: key))
		} catch let error as DecodingError {
			switch error {
				case .keyNotFound: return .none
				case .valueNotFound: return .some(.none)
				default: throw error
			}
		} catch {
			throw error
		}
	}
}
