import SwiftUI

struct HomeView: View {
    let contracts: [Contract]
    let store: HolidayStore
    let router: AppRouter
    @State private var showsAddContract = false

    var body: some View {
        Group {
            if contracts.isEmpty {
                ContentUnavailableView {
                    Label("Nenhum contrato", systemImage: "doc.badge.plus")
                } description: {
                    Text("Adicione um contrato para descobrir os próximos feriados aplicáveis.")
                } actions: {
                    Button("Adicionar contrato") { showsAddContract = true }
                        .buttonStyle(.borderedProminent)
                }
            } else if store.isLoading {
                ProgressView("Carregando feriados…")
            } else if let next = store.nextHoliday {
                ScrollView {
                    NextHolidayCard(occurrence: next, now: Date())
                        .padding()
                    if store.hasPartialFailure { partialFailure }
                }
            } else if !store.errors.isEmpty {
                errorState
            } else {
                ContentUnavailableView("Nenhum próximo feriado", systemImage: "calendar.badge.checkmark")
            }
        }
        .navigationTitle("Início")
        .rootHeader { router.showsProfile = true }
        .sheet(isPresented: $showsAddContract) { RegisterView() }
    }

    private var partialFailure: some View {
        VStack(spacing: 8) {
            Label("Algumas localizações não puderam ser atualizadas.", systemImage: "exclamationmark.triangle")
            Button("Tentar novamente") { Task { await store.retryFailures(contracts: contracts) } }
        }
        .font(.subheadline)
        .padding()
    }

    private var errorState: some View {
        ContentUnavailableView {
            Label("Não foi possível carregar", systemImage: "wifi.exclamationmark")
        } description: {
            Text("Verifique sua conexão e tente novamente.")
        } actions: {
            Button("Tentar novamente") { Task { await store.retryFailures(contracts: contracts) } }
                .buttonStyle(.borderedProminent)
        }
    }
}
