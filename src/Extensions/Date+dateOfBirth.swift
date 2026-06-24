import Foundation

fileprivate let dobFormatter: DateFormatter = {
	let formatter = DateFormatter()
	formatter.calendar = Calendar(identifier: .gregorian)
	formatter.locale = Locale(identifier: "en_US_POSIX")
	formatter.timeZone = TimeZone(secondsFromGMT: 0)
	formatter.dateFormat = "ddMMyyyy"
	return formatter
}()

extension Date {
	enum DateOfBirthError: Error {
		case invalidFormat
	}

	/// Creates a date from a date of birth string in the format "ddmmyyyy", e.g. 19 March 2002 is 19032002.
	init(dateOfBirth: String) throws {
		guard let date = dobFormatter.date(from: dateOfBirth) else {
			throw DateOfBirthError.invalidFormat
		}

		self = date
	}
}
