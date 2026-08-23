import SwiftUI

@MainActor
struct MainTabView: View {
    let contracts: [Contract]
    let store: HolidayStore
    @Bindable var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            Tab("Início", systemImage: "house.fill", value: .home) {
                NavigationStack {
                    HomeView(contracts: contracts, store: store, router: router)
                }
            }
            Tab("Feriados", systemImage: "calendar", value: .holidays) {
                NavigationStack(path: $router.holidayPath) {
                    HolidaysView(contracts: contracts, store: store, router: router)
                }
            }
            Tab("Contratos", systemImage: "doc.text.fill", value: .contracts) {
                NavigationStack(path: $router.contractPath) {
                    ContractsView(contracts: contracts, router: router)
                }
            }
            Tab(value: .search, role: .search) {
                NavigationStack {
                    SearchView(contracts: contracts, store: store, router: router)
                }
            }
        }
        .tabViewSearchActivation(.searchTabSelection)
        .sheet(isPresented: $router.showsProfile) { ProfileView() }
    }
}
