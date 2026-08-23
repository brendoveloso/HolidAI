import SwiftUI
import SwiftData

struct ContractsView: View {
    @Environment(\.modelContext) private var modelContext
    let contracts: [Contract]
    let router: AppRouter
    @State private var showsAddContract = false
    @State private var contractToDelete: Contract?

    var body: some View {
        Group {
            if contracts.isEmpty {
                ContentUnavailableView {
                    Label("Nenhum contrato", systemImage: "doc.badge.plus")
                } description: {
                    Text("Cadastre seu primeiro vínculo de trabalho.")
                } actions: {
                    Button("Adicionar contrato") { showsAddContract = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(contracts) { contract in
                        NavigationLink(value: ContractRoute.detail(contract.id)) { ContractCard(contract: contract) }
                            .swipeActions(edge: .leading) {
                                Button(contract.isActive ? "Desativar" : "Ativar") { contract.isActive.toggle() }
                                    .tint(contract.isActive ? .orange : .green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Excluir", role: .destructive) { contractToDelete = contract }
                            }
                    }
                    Section { Button("Adicionar contrato", systemImage: "plus") { showsAddContract = true } }
                }
            }
        }
        .navigationTitle("Contratos")
        .rootHeader { router.showsProfile = true }
        .sheet(isPresented: $showsAddContract) { RegisterView() }
        .confirmationDialog(
            "Excluir \(contractToDelete?.companyName ?? "contrato")?",
            isPresented: Binding(get: { contractToDelete != nil }, set: { if !$0 { contractToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Excluir contrato", role: .destructive) {
                if let contractToDelete { modelContext.delete(contractToDelete) }
                contractToDelete = nil
            }
            Button("Cancelar", role: .cancel) { contractToDelete = nil }
        } message: { Text("Essa ação não pode ser desfeita.") }
        .navigationDestination(for: ContractRoute.self) { route in
            switch route {
            case .detail(let id): ContractDetailView(contract: contracts.first { $0.id == id }, router: router)
            case .edit: EmptyView()
            }
        }
    }

}

struct ContractDetailView: View {
    let contract: Contract?
    let router: AppRouter
    @State private var showsEdit = false

    var body: some View {
        if let contract {
            List {
                LabeledContent("Empresa", value: contract.companyName)
                LabeledContent("Vínculo", value: contract.employmentType.localizedName)
                LabeledContent("UF", value: contract.state)
                LabeledContent("Cidade", value: contract.city)
                Toggle("Contrato ativo", isOn: Binding(get: { contract.isActive }, set: { contract.isActive = $0 }))
            }
            .navigationTitle(contract.companyName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Editar") { showsEdit = true } }
            .sheet(isPresented: $showsEdit) { RegisterView(contract: contract) }
        } else {
            ContentUnavailableView("Contrato indisponível", systemImage: "doc.badge.exclamationmark")
        }
    }
}
