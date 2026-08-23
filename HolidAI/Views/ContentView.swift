import SwiftUI
import SwiftData

@MainActor
struct ContentView: View {
    @Query(sort: \Contract.createdAt) private var contracts: [Contract]
    @State private var store = HolidayStore()
    @State private var router = AppRouter()

    init(repository: (any HolidayRepository)? = nil) {
        _store = State(initialValue: HolidayStore(repository: repository))
    }
    
    var body: some View {
        MainTabView(contracts: contracts, store: store, router: router)
            .task(id: contractFingerprint) { await store.load(contracts: contracts) }
    }

    private var contractFingerprint: String {
        contracts.map { "\($0.id)|\($0.companyName)|\($0.state)|\($0.city)|\($0.employmentType.rawValue)|\($0.isActive)" }.joined(separator: ";")
    }
}

#Preview {
    ContentView()
        // Injeta um container temporário na memória para o Preview não quebrar
        .modelContainer(for: Contract.self, inMemory: true)
}
