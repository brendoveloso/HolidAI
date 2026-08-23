import SwiftUI

struct HolidayTypeBadge: View {
    let type: String

    var body: some View {
        Text(type.capitalized)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Capsule())
            .accessibilityLabel("Tipo: \(type)")
    }

    private var color: Color {
        switch type.normalizedForSearch {
        case "nacional": .blue
        case "estadual": .orange
        case "municipal": .purple
        case "facultativo": .green
        default: .secondary
        }
    }
}

struct HolidayRow: View {
    let occurrence: HolidayOccurrence
    let isPast: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 1) {
                Text(occurrence.holiday.date, format: .dateTime.day(.twoDigits))
                    .font(.title3.bold())
                Text(occurrence.holiday.date, format: .dateTime.month(.abbreviated))
                    .font(.caption2.bold())
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48)
            .frame(minHeight: 48)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 5) {
                Text(occurrence.holiday.name).fontWeight(.semibold)
                HStack { HolidayTypeBadge(type: occurrence.holiday.type) }
                if !occurrence.contractNames.isEmpty {
                    Text(occurrence.contractNames.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(isPast ? 0.58 : 1)
        .accessibilityElement(children: .combine)
    }
}

struct NextHolidayCard: View {
    let occurrence: HolidayOccurrence
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Próximo feriado", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.tint)
            Text(occurrence.holiday.name)
                .font(.title2.bold())
            Text(occurrence.holiday.date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                .foregroundStyle(.secondary)
            HStack {
                HolidayTypeBadge(type: occurrence.holiday.type)
                Spacer()
                Text(daysRemainingText)
                    .font(.headline)
            }
            Divider()
            Label(contractText, systemImage: "doc.text")
                .font(.subheadline)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.quaternary))
        .accessibilityElement(children: .combine)
    }

    private var daysRemainingText: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: occurrence.holiday.date)).day ?? 0
        return days == 0 ? "Hoje" : "Faltam \(days) dias"
    }

    private var contractText: String {
        occurrence.contractNames.count == 1
            ? occurrence.contractNames[0]
            : "Aplica-se a \(occurrence.contractNames.count) contratos"
    }
}
