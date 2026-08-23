import Foundation

struct GlobalSearchResults {
    let holidays: [HolidayOccurrence]
    let contracts: [Contract]
}

enum GlobalSearch {
    static func results(query: String, holidays: [HolidayOccurrence], contracts: [Contract]) -> GlobalSearchResults {
        let term = query.normalizedForSearch
        guard !term.isEmpty else { return GlobalSearchResults(holidays: [], contracts: []) }

        return GlobalSearchResults(
            holidays: holidays.filter { occurrence in
                [occurrence.holiday.name, occurrence.holiday.type, occurrence.holiday.state, occurrence.holiday.city ?? "", occurrence.contractNames.joined(separator: " ")]
                    .contains { $0.normalizedForSearch.contains(term) }
            },
            contracts: contracts.filter { contract in
                [contract.companyName, contract.state, contract.city, contract.employmentType.localizedName]
                    .contains { $0.normalizedForSearch.contains(term) }
            }
        )
    }
}
