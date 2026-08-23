import Foundation

struct Holiday: Identifiable, Hashable, Sendable {
    let id: String
    let date: Date
    let name: String
    let type: String
    let appliesToBanking: Bool
    let year: Int
    let state: String
    let city: String?

    init(
        date: Date,
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

    private static func makeID(date: Date, name: String, type: String, state: String, city: String?) -> String {
        let day = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        return "\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)|\(name.normalizedForSearch)|\(type.normalizedForSearch)|\(state.uppercased())|\(city?.normalizedForSearch ?? "")"
    }
}

struct HolidayOccurrence: Identifiable, Hashable, Sendable {
    let holiday: Holiday
    let contractIDs: Set<UUID>
    let contractNames: [String]

    var id: String { holiday.id }
}
