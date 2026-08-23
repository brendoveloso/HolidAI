import SwiftUI
import SwiftData

@main
struct HolidAIApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Contract.self
        ])
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            if isUITesting && ProcessInfo.processInfo.arguments.contains("-ui-seed-contracts") {
                let context = ModelContext(container)
                context.insert(Contract(companyName: "Banco Ágil", state: "SP", city: "São Paulo", employmentType: .banking))
                context.insert(Contract(companyName: "Estúdio Aurora", state: "RJ", city: "Rio de Janeiro", employmentType: .pj))
                try context.save()
            }
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
                ContentView(repository: DefaultHolidayRepository(service: MockHolidayService()))
            } else {
                ContentView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
