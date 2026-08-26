import Foundation

struct HolidayDate: Hashable, Sendable, Codable, Comparable {
    let year: Int
    let month: Int
    let day: Int

    init?(year: Int, month: Int, day: Int) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.referenceTimeZone
        let components = DateComponents(year: year, month: month, day: day)

        guard
            let date = calendar.date(from: components),
            calendar.dateComponents([.year, .month, .day], from: date) == components
        else {
            return nil
        }

        self.year = year
        self.month = month
        self.day = day
    }

    init?(apiValue: String) {
        let components = apiValue.split(whereSeparator: { $0 == "/" || $0 == "-" })
        guard
            components.count == 3,
            let day = Int(components[0]),
            let month = Int(components[1]),
            let year = Int(components[2])
        else {
            return nil
        }

        self.init(year: year, month: month, day: day)
    }

    init(_ date: Date, timeZone: TimeZone = .autoupdatingCurrent) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.year = components.year!
        self.month = components.month!
        self.day = components.day!
    }

    static func < (lhs: HolidayDate, rhs: HolidayDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    var storageValue: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    func formatted(dateStyle: DateFormatter.Style) -> String {
        let formatter = Self.makeFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = .none
        return formatter.string(from: referenceDate)
    }

    func formatted(template: String) -> String {
        let formatter = Self.makeFormatter()
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: referenceDate)
    }

    func days(until other: HolidayDate) -> Int {
        Self.referenceCalendar.dateComponents(
            [.day],
            from: referenceDate,
            to: other.referenceDate
        ).day ?? 0
    }

    private static let referenceTimeZone = TimeZone(identifier: "UTC")!

    private static var referenceCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = referenceTimeZone
        return calendar
    }

    private var referenceDate: Date {
        Self.referenceCalendar.date(
            from: DateComponents(year: year, month: month, day: day)
        )!
    }

    private static func makeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = referenceCalendar
        formatter.timeZone = referenceTimeZone
        return formatter
    }
}

struct Holiday: Identifiable, Hashable, Sendable {
    let id: String
    let date: HolidayDate
    let name: String
    let type: String
    let appliesToBanking: Bool
    let year: Int
    let state: String
    let city: String?

    init(
        date: HolidayDate,
        name: String,
        type: String,
        appliesToBanking: Bool,
        year: Int,
        state: String,
        city: String?
    ) {
        self.date = date
        self.name = name
        self.type = type
        self.appliesToBanking = appliesToBanking
        self.year = year
        self.state = state
        self.city = city
        self.id = Self.makeID(date: date, name: name, type: type, state: state, city: city)
    }

    private static func makeID(date: HolidayDate, name: String, type: String, state: String, city: String?) -> String {
        "\(date.storageValue)|\(name.normalizedForSearch)|\(type.normalizedForSearch)|\(state.uppercased())|\(city?.normalizedForSearch ?? "")"
    }
}

struct HolidayOccurrence: Identifiable, Hashable, Sendable {
    let holiday: Holiday
    let contractIDs: Set<UUID>
    let contractNames: [String]

    var id: String { holiday.id }
}
