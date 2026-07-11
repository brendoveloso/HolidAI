import Foundation

struct RealHolidayService: HolidayService {
    
    private let baseURL = "https://feriadosapi.com/api/v1"
    
    // MARK: - Find States
    func fetchStates() async throws -> [StateDTO] {
        guard let url = URL(string: "\(baseURL)/estados") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(AppConfiguration.apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let result = try JSONDecoder().decode(StatesResponse.self, from: data)
        return result.states.sorted(by: { $0.name < $1.name })
    }
    
    // MARK: - Find Holidays
    func fetchHolidays(year: Int, country: String, state: String?, city: String?) async throws -> [HolidayDTO] {
        guard let uf = state else { return [] }
        
        let urlString: String
        
        // Verifica se é capital para usar o código IBGE
        if let capitalInfo = CapitalIBGEMapper.capitals[uf], city == capitalInfo.name {
            urlString = "\(baseURL)/feriados/cidade/\(capitalInfo.ibge)?ano=\(year)&facultativos=true"
        } else {
            urlString = "\(baseURL)/feriados/estado/\(uf)?ano=\(year)&facultativos=true"
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(AppConfiguration.apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        do {
            let response = try JSONDecoder().decode(HolidaysResponse.self, from: data)
            return response.holidays
        } catch let DecodingError.dataCorrupted(context) {
            print("🚨 Dados corrompidos: \(context)")
            throw DecodingError.dataCorrupted(context)
        } catch let DecodingError.keyNotFound(key, context) {
            print("🚨 Chave não encontrada: \(key.stringValue) - \(context.debugDescription)")
            throw DecodingError.keyNotFound(key, context)
        } catch let DecodingError.valueNotFound(value, context) {
            print("🚨 Valor não encontrado: \(value) - \(context.debugDescription)")
            throw DecodingError.valueNotFound(value, context)
        } catch let DecodingError.typeMismatch(type, context) {
            print("🚨 Tipo incorreto: \(type) - \(context.debugDescription)")
            throw DecodingError.typeMismatch(type, context)
        } catch {
            print("🚨 Erro desconhecido: \(error)")
            throw error
        }
    }
}

// MARK: - Decodificadores de JSON

struct StatesResponse: Codable {
    let states: [StateDTO]
    
    enum CodingKeys: String, CodingKey {
        case states = "estados"
    }
}

struct HolidaysResponse: Codable {
    let holidays: [HolidayDTO]
    
    enum CodingKeys: String, CodingKey {
        case holidays = "feriados"
    }
}
