import Foundation
import SwiftData

@MainActor
@Observable
final class RegisterViewModel {
    var states: [StateDTO] = []
    
    // Estados do formulário
    var companyName: String = ""
    var selectedState: String = ""
    var selectedCity: String = "Capital"
    var selectedEmploymentType: EmploymentType = .clt
    
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    private let holidayService: HolidayService
    
    init(holidayService: HolidayService, contract: Contract? = nil) {
        self.holidayService = holidayService
        if let contract {
            companyName = contract.companyName
            selectedState = contract.state
            selectedCity = contract.city
            selectedEmploymentType = contract.employmentType
        }
    }
    
    func loadStates() async {
        guard states.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            self.states = try await holidayService.fetchStates()
        } catch {
            print("❌ Erro na API ou no formato JSON: \(error)")
            self.errorMessage = "Erro ao ler dados: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func saveContract(_ contract: Contract?, context: ModelContext) {
        if let contract {
            contract.companyName = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
            contract.state = selectedState
            contract.city = selectedCity
            contract.employmentType = selectedEmploymentType
        } else {
            context.insert(Contract(
                companyName: companyName.trimmingCharacters(in: .whitespacesAndNewlines),
                country: "BR",
                state: selectedState,
                city: selectedCity,
                employmentType: selectedEmploymentType
            ))
        }
    }
}
