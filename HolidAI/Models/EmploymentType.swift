import Foundation

/// Tipos de vínculo suportados pelo domínio do aplicativo.
///
/// Os `rawValue`s são identificadores estáveis para persistência. Textos exibidos
/// para a pessoa usuária devem vir de `localizedName`, nunca do valor persistido.
enum EmploymentType: String, CaseIterable, Codable, Identifiable, Sendable {
    case clt
    case pj
    case banking

    var id: Self { self }

    var localizedName: String {
        switch self {
        case .clt:
            return String(localized: "CLT")
        case .pj:
            return String(localized: "PJ")
        case .banking:
            return String(localized: "Bancário")
        }
    }

    /// Converte valores persistidos e rótulos legados sem espalhar comparações de
    /// strings pelo domínio. Valores desconhecidos são rejeitados explicitamente.
    init?(persistedValue: String) {
        let normalizedValue = persistedValue
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "pt_BR"))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        switch normalizedValue.lowercased(with: Locale(identifier: "en_US_POSIX")) {
        case Self.clt.rawValue:
            self = .clt
        case Self.pj.rawValue, "contractor":
            self = .pj
        case Self.banking.rawValue, "bancario":
            self = .banking
        default:
            return nil
        }
    }
}
