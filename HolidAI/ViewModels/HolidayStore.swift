import Foundation
import Observation

@MainActor
@Observable
final class HolidayStore {
    private(set) var occurrences: [HolidayOccurrence] = []
    private(set) var nextHoliday: HolidayOccurrence?
    private(set) var isLoading = false
    private(set) var isRefreshing = false
    private(set) var errors: [HolidayLocationKey: String] = [:]

    private let repository: any HolidayRepository
    private let now: () -> Date
    private var holidaysByKey: [HolidayLocationKey: [Holiday]] = [:]

    init(repository: (any HolidayRepository)? = nil, now: @escaping () -> Date = Date.init) {
        self.repository = repository ?? DefaultHolidayRepository()
        self.now = now
    }

    var hasPartialFailure: Bool { !errors.isEmpty && !occurrences.isEmpty }

    func load(contracts: [Contract], refresh: Bool = false) async {
        let activeContracts = contracts.filter(\.isActive)
        guard !activeContracts.isEmpty else {
            occurrences = []
            nextHoliday = nil
            errors = [:]
            holidaysByKey = [:]
            return
        }

        if occurrences.isEmpty { isLoading = true } else { isRefreshing = refresh }
        defer { isLoading = false; isRefreshing = false }

        let year = HolidayDate(now()).year
        await fetch(keys: Set(activeContracts.map { key(for: $0, year: year) }), retry: refresh)
        rebuild(using: activeContracts)

        if nextHoliday == nil {
            await fetch(keys: Set(activeContracts.map { key(for: $0, year: year + 1) }), retry: refresh)
            rebuild(using: activeContracts)
        }
    }

    func retryFailures(contracts: [Contract]) async {
        guard !errors.isEmpty else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await fetch(keys: Set(errors.keys), retry: true)
        rebuild(using: contracts.filter(\.isActive))
    }

    func occurrences(for contractID: UUID?) -> [HolidayOccurrence] {
        guard let contractID else { return occurrences }
        return occurrences.filter { $0.contractIDs.contains(contractID) }
    }

    private func fetch(keys: Set<HolidayLocationKey>, retry: Bool) async {
        for key in keys {
            do {
                holidaysByKey[key] = try await repository.holidays(for: key, retry: retry)
                errors[key] = nil
            } catch {
                errors[key] = error.localizedDescription
            }
        }
    }

    private func rebuild(using contracts: [Contract]) {
        let pairs = contracts.flatMap { contract -> [(Holiday, Contract)] in
            holidaysByKey
                .filter { key, _ in
                    key.country == contract.country.uppercased()
                        && key.state == contract.state.uppercased()
                        && key.city?.normalizedForSearch == contract.city.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty?.normalizedForSearch
                }
                .flatMap(\.value)
                .filter { HolidayRules.applies($0, to: contract) }
                .map { ($0, contract) }
        }
        occurrences = HolidayRules.consolidate(pairs)
        nextHoliday = HolidayRules.nextHoliday(in: occurrences, now: now())
    }

    private func key(for contract: Contract, year: Int) -> HolidayLocationKey {
        HolidayLocationKey(year: year, country: contract.country, state: contract.state, city: contract.city)
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
