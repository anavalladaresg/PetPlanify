import SwiftUI

/// Monthly view of administered and upcoming vaccines and deworming care.
struct HealthCalendarView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.calendar) private var calendar
    @State private var displayedMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    @State private var selectedDay: Date?
    @State private var presentedSheet: HealthSheet?

    private var events: [HealthCalendarEvent] {
        var values: [HealthCalendarEvent] = []
        let now = Date.now

        let latestVaccineIDs = Set(Dictionary(grouping: store.snapshot.health.vaccines, by: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
            .values.compactMap { $0.max { $0.dateAdministered < $1.dateAdministered }?.id })
        for vaccine in store.snapshot.health.vaccines {
            values.append(HealthCalendarEvent(
                id: "vaccine-administered-\(vaccine.id)", date: vaccine.dateAdministered,
                title: vaccine.name, detail: "Administrada", kind: .vaccine,
                isUpcoming: vaccine.dateAdministered > now, symbol: "syringe", sheet: .vaccine(vaccine)
            ))
            if latestVaccineIDs.contains(vaccine.id), let nextDueDate = vaccine.nextDueDate {
                values.append(HealthCalendarEvent(
                    id: "vaccine-next-\(vaccine.id)", date: nextDueDate,
                    title: vaccine.name, detail: "Próxima vacuna", kind: .vaccine,
                    isUpcoming: nextDueDate > now, symbol: "syringe", sheet: .vaccine(vaccine)
                ))
            }
        }

        let latestDewormingIDs = Set(Dictionary(grouping: store.snapshot.health.dewormings, by: { $0.kind })
            .values.compactMap { $0.max { $0.applicationDate < $1.applicationDate }?.id })
        for deworming in store.snapshot.health.dewormings {
            values.append(HealthCalendarEvent(
                id: "deworming-applied-\(deworming.id)", date: deworming.applicationDate,
                title: deworming.kind.title, detail: deworming.productName ?? "Aplicada",
                kind: .deworming, isUpcoming: deworming.applicationDate > now,
                symbol: deworming.kind.symbol, sheet: .deworming(deworming, deworming.kind)
            ))
            if latestDewormingIDs.contains(deworming.id), let nextDueDate = deworming.nextDueDate {
                values.append(HealthCalendarEvent(
                    id: "deworming-next-\(deworming.id)", date: nextDueDate,
                    title: deworming.kind.title, detail: "Próxima desparasitación",
                    kind: .deworming, isUpcoming: nextDueDate > now,
                    symbol: deworming.kind.symbol, sheet: .deworming(deworming, deworming.kind)
                ))
            }
        }

        for medication in store.snapshot.health.medications {
            let end = medication.endDate ?? medication.startDate
            var day = calendar.startOfDay(for: medication.startDate)
            let finalDay = calendar.startOfDay(for: max(end, medication.startDate))
            var offset = 0
            while day <= finalDay && offset < 366 {
                values.append(HealthCalendarEvent(
                    id: "medication-\(medication.id)-\(offset)", date: day,
                    title: medication.name, detail: "Medicación", kind: .medication,
                    isUpcoming: day > now, symbol: "pills.fill", sheet: .medication(medication)
                ))
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
                offset += 1
            }
        }

        for visit in store.snapshot.health.visits {
            values.append(HealthCalendarEvent(
                id: "visit-\(visit.id)", date: visit.date,
                title: visit.reason, detail: "Visita veterinaria", kind: .visit,
                isUpcoming: visit.date > now, symbol: "cross.case.fill", sheet: .visitDetail(visit.id)
            ))
        }

        for weight in store.snapshot.health.weights {
            values.append(HealthCalendarEvent(
                id: "weight-\(weight.id)", date: weight.date,
                title: AppFormat.weight(weight.weight, unit: store.snapshot.preferences.weightUnit), detail: "Peso",
                kind: .weight, isUpcoming: false, symbol: "scalemass", sheet: .weight(weight)
            ))
        }
        return values.sorted { $0.date < $1.date }
    }

    private var monthDays: [Date?] {
        guard let dayRange = calendar.range(of: .day, in: .month, for: displayedMonth),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else { return [] }
        let weekday = calendar.component(.weekday, from: start)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        let days = dayRange.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
        return Array(repeating: nil, count: offset) + days.map(Optional.some)
    }

    var body: some View {
        CareSection(title: "Calendario de salud", style: .standard, symbol: "calendar") {
            monthHeader
            weekdayHeader
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Space.xs), count: 7), spacing: AppTheme.Space.sm) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }
            legend
            if let selectedDay {
                selectedDayDetails(selectedDay)
            }
        }
        .accessibilityIdentifier("health.calendar")
        .overlay(alignment: .topTrailing) {
            Button("Volver a hoy", systemImage: "calendar") { goToToday() }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(AppTheme.green)
                .frame(width: 44, height: 44)
                .padding(.top, AppTheme.Space.sm)
                .padding(.trailing, AppTheme.Space.md)
                .accessibilityLabel("Volver al día de hoy")
                .accessibilityIdentifier("health.calendar.today")
        }
        .sheet(item: $presentedSheet) { HealthSheetContent(sheet: $0) }
    }

    private var monthHeader: some View {
        HStack {
            Button("Mes anterior", systemImage: "chevron.left") { moveMonth(by: -1) }
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
                .accessibilityLabel("Mes anterior")
            Spacer()
            Text(monthTitle)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button("Mes siguiente", systemImage: "chevron.right") { moveMonth(by: 1) }
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
                .accessibilityLabel("Mes siguiente")
        }
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var weekdayHeader: some View {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        return HStack(spacing: AppTheme.Space.xs) {
            ForEach(0..<7, id: \.self) { index in
                Text(symbols[(calendar.firstWeekday - 1 + index) % 7].prefix(1).uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryInk)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private func dayCell(_ day: Date) -> some View {
        let dayEvents = events.filter { calendar.isDate($0.date, inSameDayAs: day) }
        let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        let isToday = calendar.isDateInToday(day)
        return Button {
            selectedDay = day
        } label: {
            VStack(spacing: 4) {
                Text(calendar.component(.day, from: day), format: .number)
                    .font(.subheadline.weight(isToday ? .bold : .medium))
                    .foregroundStyle(isToday ? AppTheme.green : AppTheme.ink)
                HStack(spacing: 3) {
                    ForEach(Array(dayEvents.prefix(4))) { event in
                        if event.kind == .medication {
                            Capsule().fill(event.kind.color).frame(width: 10, height: 4)
                        } else {
                            Circle().fill(event.kind.color).frame(width: 6, height: 6)
                        }
                    }
                    if dayEvents.count > 4 {
                        Text("+\(dayEvents.count - 4)").font(.system(size: 7, weight: .bold)).foregroundStyle(AppTheme.secondaryInk)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(isSelected ? AppTheme.blue.opacity(0.16) : AppTheme.surfaceMuted.opacity(dayEvents.isEmpty ? 0.18 : 0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? AppTheme.blue : isToday ? AppTheme.green : .clear, lineWidth: isSelected || isToday ? 1.5 : 1)
            }
            .overlay(alignment: .topTrailing) {
                if isToday {
                    Circle().fill(AppTheme.green).frame(width: 6, height: 6).padding(5).accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
        .accessibilityValue(dayEvents.isEmpty ? "Sin cuidados" : dayEvents.map { "\($0.title), \($0.detail)" }.joined(separator: ", "))
    }

    private var legend: some View {
        // Two roomy columns on iPhone prevent long category names from
        // splitting mid-word; macOS naturally expands to more columns.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), alignment: .leading)], alignment: .leading, spacing: AppTheme.Space.sm) {
            legendItem(title: "Vacunas", color: AppTheme.vaccine)
            legendItem(title: "Desparasitaciones", color: AppTheme.deworming)
            legendItem(title: "Medicación", color: AppTheme.medication)
            legendItem(title: "Visitas", color: AppTheme.visit)
            legendItem(title: "Peso", color: AppTheme.weight)
        }
        .padding(.top, AppTheme.Space.sm)
    }

    private func legendItem(title: LocalizedStringKey, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title).lineLimit(1).minimumScaleFactor(0.8)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(color)
    }

    @ViewBuilder
    private func selectedDayDetails(_ day: Date) -> some View {
        let dayEvents = events.filter { calendar.isDate($0.date, inSameDayAs: day) }
        VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
            Text(day.formatted(date: .long, time: .omitted))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            if dayEvents.isEmpty {
                Text("Sin cuidados registrados para este día.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
            } else {
                ForEach(dayEvents) { event in
                    Button { presentedSheet = event.sheet } label: {
                        HStack(spacing: AppTheme.Space.sm) {
                            Image(systemName: event.symbol)
                                .foregroundStyle(event.kind.color)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(event.title).font(.subheadline.weight(.medium))
                                Text(event.detail).font(.caption).foregroundStyle(AppTheme.secondaryInk)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(AppTheme.secondaryInk)
                                .accessibilityHidden(true)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("Abre el registro para editarlo")
                }
            }
        }
        .padding(AppTheme.Space.md)
        .background(AppTheme.surfaceMuted.opacity(0.55), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
    }

    private func moveMonth(by value: Int) {
        if let month = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = month
            selectedDay = nil
        }
    }

    private func goToToday() {
        displayedMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        selectedDay = calendar.startOfDay(for: .now)
    }
}

private struct HealthCalendarEvent: Identifiable {
    enum Kind: Hashable {
        case vaccine, deworming, medication, visit, weight

        var color: Color {
            switch self {
            case .vaccine: AppTheme.vaccine
            case .deworming: AppTheme.deworming
            case .medication: AppTheme.medication
            case .visit: AppTheme.visit
            case .weight: AppTheme.weight
            }
        }
        var sortOrder: Int {
            switch self {
            case .vaccine: 0
            case .deworming: 1
            case .medication: 2
            case .visit: 3
            case .weight: 4
            }
        }
    }

    let id: String
    let date: Date
    let title: String
    let detail: String
    let kind: Kind
    let isUpcoming: Bool
    let symbol: String
    let sheet: HealthSheet
}

#Preview("Calendario de salud") {
    NavigationStack { HealthCalendarView() }
        .environment(PetPlanifyStore.preview())
}
