import SwiftUI
import SwiftData

@MainActor
struct RegisterView: View {
    // Acesso ao banco de dados local do SwiftData
    @Environment(\.modelContext) private var modelContext
    // Controle para fechar a tela (modal)
    @Environment(\.dismiss) private var dismiss
    
    // Instancia ViewModel
    @State private var viewModel: RegisterViewModel
    
    @MainActor
    init() {
        let service = RealHolidayService()
        _viewModel = State(initialValue: RegisterViewModel(holidayService: service))
    }
    
    // Opções estáticas para os outros Pickers
    let employmentTypes: [String] = ["CLT", "Bancário", "PJ"]
    var cityOptions: [String] {
        if let capital = CapitalIBGEMapper.getCapitalName(for: viewModel.selectedState) {
            return [capital, "Outra Cidade"]
        }
        return ["Outra Cidade"]

    }
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Regime de Trabalho")) {
                    Picker("Categoria", selection: $viewModel.selectedEmploymentType) {
                        ForEach(employmentTypes, id: \.self) { employmentType in
                            Text(employmentType).tag(employmentType)
                        }
                    }
                }
                
                Section(header: Text("Dados da Empresa")) {
                    TextField("Nome da Empresa (Ex: Nubank)", text: $viewModel.companyName)
                }
                
                Section(header: Text("Localização")) {
                    // Trata os estados de carregamento, erro e sucesso
                    if viewModel.isLoading {
                        ProgressView("Carregando estados...")
                    } else if let erro = viewModel.errorMessage {
                        Text(erro)
                            .foregroundColor(.red)
                            .font(.caption)
                        
                        Button("Tentar novamente") {
                            Task { await viewModel.loadStates() }
                        }
                    } else {
                        // Picker dinâmico consumindo a API
                        Picker("Estado", selection: $viewModel.selectedState) {
                            Text("Selecione um estado").tag("")
                            
                            ForEach(viewModel.states) { state in
                                Text(state.name).tag(state.uf)
                            }
                        }
                        .onChange(of: viewModel.selectedState) {
                            if let capital = CapitalIBGEMapper.getCapitalName(for: viewModel.selectedState) {
                                viewModel.selectedCity = capital
                            }
                        }
                        
                        // Mostra a opção de cidade apenas se o estado foi selecionado
                        if !viewModel.selectedState.isEmpty {
                            Picker("Cidade", selection: $viewModel.selectedCity) {
                                ForEach(cityOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
                
                
            }
            .navigationTitle("Novo Contrato")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        viewModel.saveContract(context: modelContext)
                        dismiss()
                    }
                    // O botão só fica ativo se preencher o nome e escolher o estado
                    .disabled(viewModel.companyName.isEmpty || viewModel.selectedState.isEmpty)
                }
            }
            // Dispara a requisição para a API exatamente quando a tela aparece
            .task {
                await viewModel.loadStates()
            }
        }
    }
}
