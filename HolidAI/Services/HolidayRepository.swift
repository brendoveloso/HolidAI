import Foundation

nonisolated struct HolidayLocationKey: Hashable, Sendable, CustomStringConvertible {
    let year: Int
    let country: String
    let state: String
    let city: String?

    init(year: Int, country: String = "BR", state: String, city: String?) {
        self.year = year
        self.country = country.uppercased()
        self.state = state.uppercased()
        let trimmedCity = city?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.city = trimmedCity?.isEmpty == false ? trimmedCity : nil
    }

    var description: String {
        [state, city].compactMap { $0 }.joined(separator: " · ") + " · \(year)"
    }
}

protocol HolidayRepository: AnyObject {
    func holidays(for key: HolidayLocationKey, retry: Bool) async throws -> [Holiday]
}

@MainActor
final class DefaultHolidayRepository: HolidayRepository {
    private let service: any HolidayService
    private var cache: [HolidayLocationKey: [Holiday]] = [:]
    private var failures: Set<HolidayLocationKey> = []

    init(service: (any HolidayService)? = nil) {
        self.service = service ?? RealHolidayService()
    }

    func holidays(for key: HolidayLocationKey, retry: Bool = false) async throws -> [Holiday] {
        if let cached = cache[key] { return cached }
        if failures.contains(key), !retry { throw HolidayRepositoryError.previousFailure(key) }

        do {
            let dtos = try await service.fetchHolidays(
                year: key.year,
                country: key.country,
                state: key.state,
                city: key.city
            )
            let holidays = try dtos.map { try HolidayMapper.map($0, key: key) }.sorted { $0.date < $1.date }
            cache[key] = holidays
            failures.remove(key)
            return holidays
        } catch {
            failures.insert(key)
            throw error
        }
    }
}

enum HolidayRepositoryError: Error, LocalizedError {
    case invalidDate(String)
    case previousFailure(HolidayLocationKey)

    var errorDescription: String? {
        switch self {
        case .invalidDate(let value): "Data de feriado inválida: \(value)"
        case .previousFailure(let key): "A consulta de \(key.description) falhou anteriormente."
        }
    }
}

enum HolidayMapper {
    static func map(_ dto: HolidayDTO, key: HolidayLocationKey) throws -> Holiday {
        guard let date = HolidayDate(apiValue: dto.date) else {
            throw HolidayRepositoryError.invalidDate(dto.date)
        }
        return Holiday(
            date: date,
            name: dto.name,
            type: dto.type,
            appliesToBanking: dto.banking,
            year: key.year,
            state: key.state,
            city: key.city
        )
    }
}

@MainActor
final class MockHolidayRepository: HolidayRepository {
    var results: [HolidayLocationKey: Result<[Holiday], Error>]
    private(set) var requests: [HolidayLocationKey] = []

    init(results: [HolidayLocationKey: Result<[Holiday], Error>] = [:]) {
        self.results = results
    }

    func holidays(for key: HolidayLocationKey, retry: Bool = false) async throws -> [Holiday] {
        requests.append(key)
        return try results[key]?.get() ?? []
    }
}
