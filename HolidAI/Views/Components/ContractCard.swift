import SwiftUI

struct ContractCard: View {
    let contract: Contract

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(contract.companyName).font(.headline)
                Spacer()
                if !contract.isActive {
                    Text("Inativo").font(.caption.bold()).foregroundStyle(.secondary)
                }
            }
            Label(location, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(contract.employmentType.localizedName)
                .font(.caption.bold())
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(.quaternary, in: Capsule())
        }
        .padding(.vertical, 6)
        .opacity(contract.isActive ? 1 : 0.65)
        .accessibilityElement(children: .combine)
    }

    private var location: String {
        contract.city.isEmpty ? contract.state : "\(contract.city), \(contract.state)"
    }
}
