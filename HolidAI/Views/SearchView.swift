import SwiftUI

struct SearchView: View {
    let contracts: [Contract]
    let store: HolidayStore
    let router: AppRouter
    @State private var query = ""
    @State private var searchIsPresented = false

    var body: some View {
        Group {
            if normalizedQuery.isEmpty {
                ContentUnavailableView("Busque por feriado, empresa, UF ou vínculo", systemImage: "magnifyingglass")
            } else if results.holidays.isEmpty && results.contracts.isEmpty {
                ContentUnavailableView("Nenhum resultado para “\(query.trimmingCharacters(in: .whitespacesAndNewlines))”", systemImage: "magnifyingglass")
            } else {
                List {
                    if !results.holidays.isEmpty {
                        Section("Feriados") {
                            ForEach(results.holidays) { occurrence in
                                Button { router.openHoliday(occurrence.id) } label: {
                                    HolidayRow(occurrence: occurrence, isPast: occurrence.holiday.date < HolidayDate(Date()))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    if !results.contracts.isEmpty {
                        Section("Contratos") {
                            ForEach(results.contracts) { contract in
                                Button { router.openContract(contract.id) } label: { ContractCard(contract: contract) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $query, isPresented: $searchIsPresented, prompt: "Buscar feriados ou contratos")
        .onAppear { searchIsPresented = true }
        .onDisappear { query = "" }
        .onChange(of: searchIsPresented) { _, isPresented in
            if !isPresented && router.selectedTab == .search { router.cancelSearch() }
        }
    }

    private var normalizedQuery: String { query.normalizedForSearch }

    private var results: GlobalSearchResults {
        GlobalSearch.results(query: query, holidays: store.occurrences, contracts: contracts)
    }
}
