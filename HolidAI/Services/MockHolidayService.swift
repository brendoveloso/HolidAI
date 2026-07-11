import Foundation

struct MockHolidayService: HolidayService {
    private let baseURL = "https://feriadosapi.com/api/v1"
    
    func fetchStates() async throws -> [StateDTO] {
        // Simula um pequeno atraso para parecer real
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Retorna estados falsos sem bater na internet
        return [
            StateDTO(uf: "RJ", name: "Rio de Janeiro"),
            StateDTO(uf: "SP", name: "São Paulo"),
            StateDTO(uf: "MG", name: "Minas Gerais")
        ]
    }
    
    func fetchHolidays(year: Int, country: String, state: String?, city: String?) async throws -> [HolidayDTO] {
        // Simula um pequeno atraso de rede de 0.5 segundos para parecer real
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Dados fictícios que serão retornados para testarmos o app
        return [
            HolidayDTO(date: "01-01-\(year)", name: "Confraternização Universal", type: "Nacional", banking: true),
            HolidayDTO(date: "21-04-\(year)", name: "Tiradentes", type: "Nacional", banking: false),
            HolidayDTO(date: "01-05-\(year)", name: "Dia do Trabalhador", type: "Nacional", banking: true),
            HolidayDTO(date: "09-07-\(year)", name: "Revolução Constitucionalista", type: "Estadual", banking: true),
            HolidayDTO(date: "25-12-\(year)", name: "Natal", type: "Nacional", banking: true)
        ]
    }
}
