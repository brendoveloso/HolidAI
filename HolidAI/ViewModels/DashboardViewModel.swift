import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    // Propriedades que a View vai observar para se atualizar automaticamente
    var holidays: [HolidayCache] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    // Dependências da ViewModel
    private let holidayService: HolidayService
    
    // Inicializador permitindo Injeção de Dependência
    init(holidayService: HolidayService) {
        self.holidayService = holidayService
    }
        
    /// Função principal que busca e processa os feriados
    @MainActor
    func loadHolidays(for contract: Contract) async {
        isLoading = true
        errorMessage = nil
        
        let currentYear = Calendar.current.component(.year, from: Date())
        
        
        do {
            let dtos = try await holidayService.fetchHolidays(
                year: currentYear,
                country: contract.country,
                state: contract.state.isEmpty ? nil : contract.state,
                city: contract.city.isEmpty ? nil : contract.city
            )
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            
            let processedHolidays = dtos.compactMap { dto -> HolidayCache? in
                // Regra de Negócio: Filtra Facultativos
                if dto.type.uppercased() == "FACULTATIVO" {
                    // Só mantém se o usuário for Bancário E o feriado permitir bancários
                    let isBancario = contract.employmentType.uppercased() == "BANCÁRIO"
                    if !(isBancario && dto.banking) {
                        return nil // Remove da lista
                    }
                }
                
                let holidayDate = dateFormatter.date(from: dto.date) ?? Date()
                return HolidayCache(date: holidayDate, name: dto.name, type: dto.type, year: currentYear)
            }
            
            self.holidays = processedHolidays.sorted(by:  { $0.date < $1.date })
            
        } catch {
            print("Erro no carregamento: \(error)") // Ajuda no debug pelo console
            self.errorMessage = "Erro ao carregar feriados: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
