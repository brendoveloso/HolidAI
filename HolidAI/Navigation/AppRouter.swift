import Foundation
import Observation

enum AppTab: Hashable {
    case home
    case holidays
    case contracts
    case search
}

enum HolidayRoute: Hashable {
    case detail(String)
}

enum ContractRoute: Hashable {
    case detail(UUID)
    case edit(UUID)
}

@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home {
        didSet {
            if selectedTab != .search { lastContentTab = selectedTab }
        }
    }
    private(set) var lastContentTab: AppTab = .home
    var holidayPath: [HolidayRoute] = []
    var contractPath: [ContractRoute] = []
    var showsProfile = false

    func openHoliday(_ id: String) {
        selectedTab = .holidays
        holidayPath = [.detail(id)]
    }

    func openContract(_ id: UUID) {
        selectedTab = .contracts
        contractPath = [.detail(id)]
    }

    func cancelSearch() {
        selectedTab = lastContentTab
    }
}
