import SwiftUI

@MainActor
struct MainTabView: View {
    let contract: Contract
    
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(contract: contract)
                    
            }
            .tabItem {
                Label("Feriados", systemImage: "calendar")
            }
            NavigationStack {
                Text("Lista de contratos (Em breve)")
                    
            }
            .tabItem {
                Label("Contrato", systemImage: "doc.text.fill")
            }
        }
    }
}

