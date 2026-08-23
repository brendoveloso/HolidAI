import Foundation

// Esse protocolo define as regras para qualquer serviço de feriados no app
protocol HolidayService: Sendable {
    func fetchStates() async throws -> [StateDTO]
    func fetchHolidays(year: Int, country: String, state: String?, city: String?) async throws -> [HolidayDTO]
}

struct HolidayDTO: Codable, Sendable {
    let date: String
    let name: String
    let type: String
    let banking: Bool
    
    enum CodingKeys: String, CodingKey {
        case date = "data"
        case name = "nome"
        case type = "tipo"
        case banking = "bancario"
    }
}

struct StateDTO: Codable, Identifiable, Sendable {
    var id: String { uf }
    let uf: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case uf = "uf"
        case name = "nome"
    }
}
