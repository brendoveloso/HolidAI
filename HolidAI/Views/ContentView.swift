import SwiftUI
import SwiftData

@MainActor
struct ContentView: View {
    @Query private var contracts: [Contract]
    
    var body: some View {
        if let activeContract = contracts.first {
            DashboardView(contract: activeContract)
        } else {
            RegisterView()
        }
    }
}

#Preview {
    ContentView()
        // Injeta um container temporário na memória para o Preview não quebrar
        .modelContainer(for: Contract.self, inMemory: true)
}
