import Foundation

enum AppConfiguration {
    static var apiKey: String {
        // Busca o valor injetado no Info.plist
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String else {
            fatalError("API_KEY não configurada no arquivo Secrets.xcconfig")
        }
        return apiKey
    }
}
