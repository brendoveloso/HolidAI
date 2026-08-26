import Foundation

enum HolidayRules {
    static func applies(_ holiday: Holiday, to contract: Contract) -> Bool {
        guard holiday.type.normalizedForSearch == "facultativo" else { return true }
        return contract.employmentType == .banking && holiday.appliesToBanking
    }

    static func consolidate(_ pairs: [(Holiday, Contract)]) -> [HolidayOccurrence] {
        let grouped = Dictionary(grouping: pairs, by: { consolidationKey(for: $0.0) })
        return grouped.values.compactMap { group in
            guard let holiday = group.first?.0 else { return nil }
            let contracts = Dictionary(grouping: group.map(\.1), by: \.id).compactMap(\.value.first)
            return HolidayOccurrence(
                holiday: holiday,
                contractIDs: Set(contracts.map(\.id)),
                contractNames: contracts.map(\.companyName).sorted()
            )
        }.sorted { lhs, rhs in
            if lhs.holiday.date != rhs.holiday.date { return lhs.holiday.date < rhs.holiday.date }
            return lhs.holiday.name.localizedStandardCompare(rhs.holiday.name) == .orderedAscending
        }
    }

    static func nextHoliday(in occurrences: [HolidayOccurrence], now: Date, timeZone: TimeZone = .autoupdatingCurrent) -> HolidayOccurrence? {
        let today = HolidayDate(now, timeZone: timeZone)
        return occurrences.filter { $0.holiday.date >= today }.min { $0.holiday.date < $1.holiday.date }
    }

    private static func consolidationKey(for holiday: Holiday) -> String {
        "\(holiday.date.storageValue)|\(holiday.name.normalizedForSearch)|\(holiday.type.normalizedForSearch)"
    }
}
