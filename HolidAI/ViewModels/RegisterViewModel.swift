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
    var selectedEmploymentType: String = "CLT"
    
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    private let holidayService: HolidayService
    
    init(holidayService: HolidayService) {
        self.holidayService = holidayService
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
    
    func saveContract(context: ModelContext) {
        let newContract = Contract(
            companyName: companyName,
            country: "BR",
            state: selectedState,
            city: selectedCity,
            employmentType: selectedEmploymentType
        )
        context.insert(newContract)
    }
}
