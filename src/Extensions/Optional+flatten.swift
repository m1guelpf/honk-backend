import Foundation
import SQLiteData

public extension Optional where Wrapped: _OptionalProtocol {
	func flatten() -> Wrapped.Wrapped? {
		flatMap(\._wrapped)
	}
}
