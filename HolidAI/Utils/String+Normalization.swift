import Foundation

extension String {
    var normalizedForSearch: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "pt_BR"))
            .split(whereSeparator: \Character.isWhitespace)
            .joined(separator: " ")
            .lowercased(with: Locale(identifier: "en_US_POSIX"))
    }
}
