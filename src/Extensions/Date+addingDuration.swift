import Foundation

extension Date {
    func adding(_ duration: Duration) -> Date {
        addingTimeInterval(duration.timeInterval)
    }
}

extension Duration {
    var timeInterval: TimeInterval {
        Double(components.seconds)
    }

    static func minutes(_ minutes: Int) -> Duration {
        .seconds(minutes * 60)
    }

    static func hours(_ hours: Int) -> Duration {
        .minutes(hours * 60)
    }

    static func days(_ days: Int) -> Duration {
        .hours(days * 24)
    }

    static func weeks(_ weeks: Int) -> Duration {
        .days(weeks * 7)
    }
}
