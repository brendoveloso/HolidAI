//
//  HolidAITests.swift
//  HolidAITests
//
//  Created by Brendo Veloso on 02/07/26.
//

import Foundation
import Testing
@testable import HolidAI

@MainActor
struct HolidAITests {

    @Test("Tipos de vínculo usam valores persistidos estáveis")
    func employmentTypeStablePersistedValues() {
        #expect(EmploymentType.clt.rawValue == "clt")
        #expect(EmploymentType.pj.rawValue == "pj")
        #expect(EmploymentType.banking.rawValue == "banking")
    }

    @Test("Tipos de vínculo apresentam rótulos localizados")
    func employmentTypeLocalizedNames() {
        #expect(EmploymentType.clt.localizedName == "CLT")
        #expect(EmploymentType.pj.localizedName == "PJ")
        #expect(EmploymentType.banking.localizedName == "Bancário")
    }

    @Test(
        "Valores persistidos e legados são mapeados para o domínio",
        arguments: [
            ("clt", EmploymentType.clt),
            ("CLT", EmploymentType.clt),
            ("contractor", EmploymentType.pj),
            ("PJ", EmploymentType.pj),
            ("banking", EmploymentType.banking),
            ("Bancário", EmploymentType.banking),
            ("  BANCARIO  ", EmploymentType.banking)
        ]
    )
    func employmentTypeMapping(value: String, expected: EmploymentType) {
        #expect(EmploymentType(persistedValue: value) == expected)
    }

    @Test("Valores de vínculo desconhecidos não recebem fallback implícito")
    func unknownEmploymentType() {
        #expect(EmploymentType(persistedValue: "estágio") == nil)
    }

    @Test("Normalização ignora acentos, caixa e espaços excedentes")
    func searchNormalization() {
        #expect("  SÃO   Paulo  ".normalizedForSearch == "sao paulo")
        #expect("BANCÁRIO".normalizedForSearch == "bancario")
    }

    @Test("Facultativo aplica-se apenas ao vínculo bancário quando indicado pela API")
    func optionalHolidayApplicability() {
        let optionalBanking = holiday(name: "Dia facultativo", type: "FACULTATIVO", banking: true)
        let optionalNonBanking = holiday(name: "Outro", type: "facultativo", banking: false)
        #expect(!HolidayRules.applies(optionalBanking, to: contract(type: .clt)))
        #expect(!HolidayRules.applies(optionalBanking, to: contract(type: .pj)))
        #expect(HolidayRules.applies(optionalBanking, to: contract(type: .banking)))
        #expect(!HolidayRules.applies(optionalNonBanking, to: contract(type: .banking)))
        #expect(HolidayRules.applies(holiday(name: "Natal", type: "Nacional"), to: contract(type: .clt)))
    }

    @Test("Próximo feriado descarta datas passadas")
    func nextHolidayDiscardsPastDates() {
        let past = occurrence(holiday: holiday(date: date(2026, 8, 1), name: "Passado"))
        let next = occurrence(holiday: holiday(date: date(2026, 9, 7), name: "Independência"))
        let later = occurrence(holiday: holiday(date: date(2026, 10, 12), name: "Padroeira"))
        #expect(HolidayRules.nextHoliday(in: [later, past, next], now: date(2026, 8, 23), calendar: calendar)?.holiday.name == "Independência")
    }

    @Test("Feriado compartilhado é consolidado entre contratos")
    func holidayDeduplication() {
        let shared = holiday(name: "Natal")
        let first = contract(name: "Empresa A", type: .clt)
        let second = contract(name: "Empresa B", type: .pj)
        let consolidated = HolidayRules.consolidate([(shared, first), (shared, second)])
        #expect(consolidated.count == 1)
        #expect(consolidated[0].contractIDs == Set([first.id, second.id]))
    }

    @Test("Repository mantém cache por localização e ano")
    func repositoryCache() async throws {
        let service = CountingHolidayService()
        let repository = DefaultHolidayRepository(service: service)
        let key = HolidayLocationKey(year: 2026, state: "SP", city: "São Paulo")
        _ = try await repository.holidays(for: key, retry: false)
        _ = try await repository.holidays(for: key, retry: false)
        #expect(service.holidayRequestCount == 1)
    }

    @Test("Repository só repete uma chave com falha quando retry é solicitado")
    func repositorySelectiveRetry() async throws {
        let service = CountingHolidayService(failuresBeforeSuccess: 1)
        let repository = DefaultHolidayRepository(service: service)
        let key = HolidayLocationKey(year: 2026, state: "RJ", city: nil)
        await #expect(throws: (any Error).self) { try await repository.holidays(for: key, retry: false) }
        await #expect(throws: (any Error).self) { try await repository.holidays(for: key, retry: false) }
        #expect(service.holidayRequestCount == 1)
        _ = try await repository.holidays(for: key, retry: true)
        #expect(service.holidayRequestCount == 2)
    }

    @Test("Store preserva sucesso quando outra localização falha")
    func partialFailureAggregation() async {
        let now = date(2026, 8, 23)
        let spKey = HolidayLocationKey(year: 2026, state: "SP", city: "São Paulo")
        let rjKey = HolidayLocationKey(year: 2026, state: "RJ", city: "Rio de Janeiro")
        let repository = MockHolidayRepository(results: [
            spKey: .success([holiday(date: date(2026, 9, 7), name: "Independência", state: "SP", city: "São Paulo")]),
            rjKey: .failure(URLError(.notConnectedToInternet))
        ])
        let store = HolidayStore(repository: repository, now: { now })
        await store.load(contracts: [contract(name: "SP", state: "SP", city: "São Paulo"), contract(name: "RJ", state: "RJ", city: "Rio de Janeiro")])
        #expect(store.occurrences.count == 1)
        #expect(store.hasPartialFailure)
    }

    @Test("Store consulta o ano seguinte quando o atual não tem próxima data")
    func nextYearFallback() async {
        let current = HolidayLocationKey(year: 2026, state: "SP", city: "São Paulo")
        let next = HolidayLocationKey(year: 2027, state: "SP", city: "São Paulo")
        let repository = MockHolidayRepository(results: [
            current: .success([holiday(date: date(2026, 1, 1), name: "Passado", state: "SP", city: "São Paulo")]),
            next: .success([holiday(date: date(2027, 1, 1), name: "Ano Novo", year: 2027, state: "SP", city: "São Paulo")])
        ])
        let store = HolidayStore(repository: repository, now: { date(2026, 12, 31) })
        await store.load(contracts: [contract(state: "SP", city: "São Paulo")])
        #expect(store.nextHoliday?.holiday.name == "Ano Novo")
        #expect(repository.requests.contains(next))
    }

    @Test("Busca cobre nome, tipo, empresa, UF, cidade e vínculo")
    func globalSearchFields() {
        let bank = contract(name: "Banco Ágil", state: "SP", city: "São Paulo", type: .banking)
        let item = occurrence(holiday: holiday(name: "Revolução Constitucionalista", type: "Estadual"), contracts: [bank])
        #expect(GlobalSearch.results(query: "revolucao", holidays: [item], contracts: [bank]).holidays.count == 1)
        #expect(GlobalSearch.results(query: "estadual", holidays: [item], contracts: [bank]).holidays.count == 1)
        #expect(GlobalSearch.results(query: "banco", holidays: [item], contracts: [bank]).contracts.count == 1)
        #expect(GlobalSearch.results(query: "sp", holidays: [item], contracts: [bank]).contracts.count == 1)
        #expect(GlobalSearch.results(query: "sao paulo", holidays: [item], contracts: [bank]).contracts.count == 1)
        #expect(GlobalSearch.results(query: "bancario", holidays: [item], contracts: [bank]).contracts.count == 1)
    }

    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func holiday(date: Date? = nil, name: String, type: String = "Nacional", banking: Bool = false, year: Int = 2026, state: String = "SP", city: String? = "São Paulo") -> Holiday {
        Holiday(date: date ?? self.date(year, 12, 25), name: name, type: type, appliesToBanking: banking, year: year, state: state, city: city)
    }

    private func contract(name: String = "Empresa", state: String = "SP", city: String = "São Paulo", type: EmploymentType = .clt) -> Contract {
        Contract(companyName: name, state: state, city: city, employmentType: type)
    }

    private func occurrence(holiday: Holiday, contracts: [Contract] = []) -> HolidayOccurrence {
        HolidayOccurrence(holiday: holiday, contractIDs: Set(contracts.map(\.id)), contractNames: contracts.map(\.companyName))
    }

}

@MainActor
private final class CountingHolidayService: HolidayService, @unchecked Sendable {
    private(set) var holidayRequestCount = 0
    private var failuresBeforeSuccess: Int

    init(failuresBeforeSuccess: Int = 0) { self.failuresBeforeSuccess = failuresBeforeSuccess }

    func fetchStates() async throws -> [StateDTO] { [] }

    func fetchHolidays(year: Int, country: String, state: String?, city: String?) async throws -> [HolidayDTO] {
        holidayRequestCount += 1
        if failuresBeforeSuccess > 0 {
            failuresBeforeSuccess -= 1
            throw URLError(.notConnectedToInternet)
        }
        return [HolidayDTO(date: "25/12/\(year)", name: "Natal", type: "Nacional", banking: false)]
    }
}
