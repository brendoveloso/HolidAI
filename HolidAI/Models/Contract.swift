import Foundation
import SwiftData

@Model
final class Contract {
    var companyName: String
    var country: String
    var state: String
    var city: String
    var employmentType: String
    var bankCode: String?
    
    init(companyName: String = "", country: String = "BR", state: String = "", city: String = "", employmentType: String = "CLT", bankCode: String? = nil) {
        self.companyName = companyName
        self.country = country
        self.state = state
        self.city = city
        self.employmentType = employmentType
        self.bankCode = bankCode
    }
}
