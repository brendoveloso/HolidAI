import SwiftUI
import SwiftData

@MainActor
struct DashboardView: View {
    // Recebe o contrato atual que vem da tela anterior/principal
    let contract: Contract
    
    @State var viewModel: DashboardViewModel
    
    @MainActor
    init(contract: Contract, viewModel: DashboardViewModel? = nil) {
        self.contract = contract
        let service = RealHolidayService()
        _viewModel = State(initialValue: viewModel ?? DashboardViewModel(holidayService: service))
    }

    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Buscando feriados inteligentes...")
                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label("Erro ao Carregar", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Tentar Novamente") {
                            Task { await viewModel.loadHolidays(for: contract) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if viewModel.holidays.isEmpty {
                    ContentUnavailableView("Nenhum feriado encontrado", systemImage: "calendar.badge.exclamationmark")
                } else {
                    List(viewModel.holidays) { holiday in
                        HStack(spacing: 16) {
                            // Badge visual para a data (estilo calendário)
                            VStack {
                                Text(formatarData(holiday.date, formato: "dd"))
                                    .font(.title2)
                                    .bold()
                                Text(formatarData(holiday.date, formato: "MMM").uppercased())
                                    .font(.caption2)
                                    .bold()
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 50)
                            .padding(.vertical, 4)
                            .background(Color(.systemGroupedBackground))
                            .cornerRadius(8)
                            
                            // Detalhes do Feriado
                            VStack(alignment: .leading, spacing: 4) {
                                Text(holiday.name)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                
                                HStack {
                                    Text(holiday.type)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(corPorTipo(holiday.type).opacity(0.15))
                                        .foregroundStyle(corPorTipo(holiday.type))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("HolidAI")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    VStack(alignment: .trailing) {
                        Text(contract.companyName)
                            .font(.subheadline)
                            .bold()
                        Text(contract.employmentType)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            // Dispara a busca assim que a tela aparece usando Concorrência Estruturada
            .task {
                await viewModel.loadHolidays(for: contract)
            }
        }
    }
    
    // MARK: - Auxiliares de Interface
    
    private func formatarData(_ data: Date, formato: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = formato
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: data)
    }
    
    private func corPorTipo(_ tipo: String) -> Color {
        switch tipo.lowercased() {
        case "nacional": return .blue
        case "estadual": return .orange
        case "municipal": return .purple
        case "regime": return .green // Cor especial para o nicho de regras customizadas do app
        default: return .gray
        }
    }
}

// Preview configurado simulando um ambiente com dados injetados na memória
#Preview { @MainActor in
    let modeloFalso = Contract(companyName: "Bradesco", country: "BR", state: "SP", city: "Osasco", employmentType: "BANCÁRIO")
    let mockService = MockHolidayService()
    let mockViewModel = DashboardViewModel(holidayService: mockService)
    
    DashboardView(contract: modeloFalso, viewModel: mockViewModel)
}
