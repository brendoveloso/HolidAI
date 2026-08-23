import SwiftUI

struct HolidaysView: View {
    let contracts: [Contract]
    let store: HolidayStore
    let router: AppRouter
    @State private var selectedContractID: UUID?

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView("Carregando feriados…")
            } else if filteredOccurrences.isEmpty {
                ContentUnavailableView("Nenhum feriado encontrado", systemImage: "calendar.badge.exclamationmark")
            } else {
                ScrollViewReader { proxy in
                    List {
                        if store.hasPartialFailure {
                            Section {
                                Button("Tentar localizações com falha novamente") {
                                    Task { await store.retryFailures(contracts: contracts) }
                                }
                            } footer: { Text("Os demais feriados continuam disponíveis.") }
                        }
                        ForEach(monthGroups, id: \.month) { group in
                            Section(group.title) {
                                ForEach(group.items) { occurrence in
                                    NavigationLink(value: HolidayRoute.detail(occurrence.id)) {
                                        HolidayRow(occurrence: occurrence, isPast: occurrence.holiday.date < Calendar.current.startOfDay(for: Date()))
                                    }
                                    .id(occurrence.id)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .task(id: selectedContractID) {
                        await Task.yield()
                        if let nextID = HolidayRules.nextHoliday(in: filteredOccurrences, now: Date())?.id {
                            proxy.scrollTo(nextID, anchor: .top)
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if !contracts.isEmpty {
                Picker("Contrato", selection: $selectedContractID) {
                    Text("Todos").tag(UUID?.none)
                    ForEach(contracts) { Text($0.companyName).tag(Optional($0.id)) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(.bar)
            }
        }
        .navigationTitle("Feriados")
        .rootHeader { router.showsProfile = true }
        .navigationDestination(for: HolidayRoute.self) { route in
            switch route {
            case .detail(let id):
                HolidayDetailView(occurrence: store.occurrences.first { $0.id == id })
            }
        }
    }

    private var filteredOccurrences: [HolidayOccurrence] { store.occurrences(for: selectedContractID) }

    private var monthGroups: [(month: Date, title: String, items: [HolidayOccurrence])] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredOccurrences) {
            calendar.date(from: calendar.dateComponents([.year, .month], from: $0.holiday.date)) ?? $0.holiday.date
        }.map { month, items in
            (month, month.formatted(.dateTime.month(.wide).year()), items.sorted { $0.holiday.date < $1.holiday.date })
        }.sorted { $0.month < $1.month }
    }
}

struct HolidayDetailView: View {
    let occurrence: HolidayOccurrence?

    var body: some View {
        if let occurrence {
            List {
                LabeledContent("Data", value: occurrence.holiday.date.formatted(date: .long, time: .omitted))
                LabeledContent("Tipo", value: occurrence.holiday.type)
                LabeledContent("Localização", value: [occurrence.holiday.city, occurrence.holiday.state].compactMap { $0 }.joined(separator: ", "))
                Section("Contratos") { ForEach(occurrence.contractNames, id: \.self) { Text($0) } }
            }
            .navigationTitle(occurrence.holiday.name)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Feriado indisponível", systemImage: "calendar.badge.exclamationmark")
        }
    }
}
