import Foundation

struct MockHolidayService: HolidayService {
    func fetchStates() async throws -> [StateDTO] {
        return [
            StateDTO(uf: "RJ", name: "Rio de Janeiro"),
            StateDTO(uf: "SP", name: "São Paulo"),
            StateDTO(uf: "MG", name: "Minas Gerais")
        ]
    }
    
    func fetchHolidays(year: Int, country: String, state: String?, city: String?) async throws -> [HolidayDTO] {
        return [
            HolidayDTO(date: "01/01/\(year)", name: "Confraternização Universal", type: "Nacional", banking: true),
            HolidayDTO(date: "21/04/\(year)", name: "Tiradentes", type: "Nacional", banking: false),
            HolidayDTO(date: "07/09/\(year)", name: "Independência do Brasil", type: "Nacional", banking: true),
            HolidayDTO(date: "12/10/\(year)", name: "Nossa Senhora Aparecida", type: "Nacional", banking: true),
            HolidayDTO(date: "25/12/\(year)", name: "Natal", type: "Nacional", banking: true)
        ]
    }
}
