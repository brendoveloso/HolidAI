import Foundation
import SwiftData

@Model
final class Contract {
    @Attribute(.unique) var id: UUID
    var companyName: String
    var country: String
    var state: String
    var city: String
    private(set) var employmentTypeRawValue: String
    var isActive: Bool
    var createdAt: Date
    var bankCode: String?

    var employmentType: EmploymentType {
        get { EmploymentType(persistedValue: employmentTypeRawValue) ?? .clt }
        set { employmentTypeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        companyName: String = "",
        country: String = "BR",
        state: String = "",
        city: String = "",
        employmentType: EmploymentType = .clt,
        isActive: Bool = true,
        createdAt: Date = Date(),
        bankCode: String? = nil
    ) {
        self.id = id
        self.companyName = companyName
        self.country = country
        self.state = state
        self.city = city
        self.employmentTypeRawValue = employmentType.rawValue
        self.isActive = isActive
        self.createdAt = createdAt
        self.bankCode = bankCode
    }
}
