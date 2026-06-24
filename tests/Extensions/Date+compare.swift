import Foundation

extension Date {
	func `is`(_ other: Date) -> Bool {
		Int(timeIntervalSince1970) == Int(other.timeIntervalSince1970)
	}
}
