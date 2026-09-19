import SwiftUI

struct HealthView: View {
    @Environment(PetPlanifyStore.self) private var store
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @State private var sheet: HealthSheet?
    @State private var showObservation = false
    @State private var observation: PetObservation?
    @State private var observationDetail: PetObservation?
    @State private var showsAllObservations = false
    @State private var expandedHistory: Set<HealthHistorySection> = []

    private enum HealthHistorySection: Hashable { case vaccines, dewormings, medications, visits }

    private var health: HealthData { store.snapshot.health }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
        CarePage {
            healthSummary
            if let next = nextCare {
                CareSection(title: "Próximo cuidado", style: .highlighted) {
                    HealthRecordRow(title: next.title, subtitle: AppFormat.date(next.date), symbol: next.symbol, statusColor: AppTheme.green) {
                        sheet = next.sheet
                    }
                }
            }
            HealthCalendarView()
            healthQuickActions
            HealthWeightCard(onRegister: { sheet = .weight(nil) }, onHistory: { sheet = .history(.weights) })
            vaccines
            dewormings
            medications
            visits
            observations
            Text("Estos registros no sustituyen la valoración de un profesional veterinario.")
                .font(.caption).foregroundStyle(AppTheme.secondaryInk)
        }
        }
        .accessibilityIdentifier("health.screen")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Registrar peso", systemImage: "scalemass") { sheet = .weight(nil) }.accessibilityIdentifier("weight.add")
                    Button("Añadir vacuna", systemImage: "syringe") { sheet = .vaccine(nil) }.accessibilityIdentifier("health.addVaccine")
                    Button("Añadir desparasitación", systemImage: "pills") { sheet = .deworming(nil, .internalDeworming) }.accessibilityIdentifier("health.addDeworming")
                    Button("Añadir medicación", systemImage: "pills.fill") { sheet = .medication(nil) }.accessibilityIdentifier("health.addMedication")
                    Button("Añadir cita veterinaria", systemImage: "cross.case") { sheet = .visit(nil) }.accessibilityIdentifier("health.addVisit")
                    Button("Añadir observación", systemImage: "text.bubble") { observation = nil; showObservation = true }
                } label: { Label("Añadir registro", systemImage: "plus") }
                .accessibilityIdentifier("health.addRecord")
            }
        }
        .sheet(item: $sheet) { HealthSheetContent(sheet: $0) }
        .sheet(isPresented: $showObservation) { ObservationEditor(context: .health, record: observation) }
        .sheet(item: $observationDetail) { ObservationDetailView(record: $0) }
    }

    private var healthSummary: some View {
        CareSection(title: "Resumen de salud", style: .highlighted, symbol: "heart.text.square.fill") {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppTheme.Space.lg) { healthMetrics }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Space.md) { healthMetrics }
            }
        }
    }

    @ViewBuilder
    private var healthMetrics: some View {
        healthMetric(
            value: store.currentWeight.map { AppFormat.weight($0, unit: store.snapshot.preferences.weightUnit) } ?? "—",
            label: "Peso actual",
            symbol: "scalemass",
            accent: AppTheme.health
        )
        healthMetric(value: "\(health.vaccines.count)", label: "Vacunas", symbol: "syringe", accent: AppTheme.vaccine)
        healthMetric(value: "\(health.dewormings.count)", label: "Desparasitaciones", symbol: "pills", accent: AppTheme.deworming)
        healthMetric(value: "\(health.visits.count)", label: "Visitas", symbol: "cross.case.fill", accent: AppTheme.visit)
    }

    private func healthMetric(value: String, label: LocalizedStringKey, symbol: String, accent: Color) -> some View {
        HStack(spacing: AppTheme.Space.sm) {
            CareSymbol(systemName: symbol, accent: accent, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.headline.monospacedDigit()).foregroundStyle(AppTheme.ink)
                Text(label).font(.caption).foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var healthQuickActions: some View {
        Group {
            #if os(iOS)
            if horizontalSizeClass == .compact {
                // 3 + 2 keeps the second row balanced. An adaptive grid would
                // otherwise leave Peso alone on a third row on iPhone.
                VStack(spacing: AppTheme.Space.sm) {
                    HStack(spacing: AppTheme.Space.sm) {
                        healthAction(title: "Vacuna", symbol: "syringe", accent: AppTheme.vaccine) { sheet = .vaccine(nil) }
                        healthAction(title: "Desparasitación", symbol: "pills", accent: AppTheme.deworming) { sheet = .deworming(nil, .internalDeworming) }
                        healthAction(title: "Medicación", symbol: "pills.fill", accent: AppTheme.medication) { sheet = .medication(nil) }
                    }
                    HStack(spacing: AppTheme.Space.sm) {
                        healthAction(title: "Visita", symbol: "cross.case.fill", accent: AppTheme.visit) { sheet = .visit(nil) }
                        healthAction(title: "Peso", symbol: "scalemass", accent: AppTheme.weight) { sheet = .weight(nil) }
                    }
                }
            } else {
                wideHealthQuickActions
            }
            #else
            wideHealthQuickActions
            #endif
        }
    }

    private var wideHealthQuickActions: some View {
        HStack(spacing: AppTheme.Space.sm) {
            healthAction(title: "Vacuna", symbol: "syringe", accent: AppTheme.vaccine) { sheet = .vaccine(nil) }
            healthAction(title: "Desparasitación", symbol: "pills", accent: AppTheme.deworming) { sheet = .deworming(nil, .internalDeworming) }
            healthAction(title: "Medicación", symbol: "pills.fill", accent: AppTheme.medication) { sheet = .medication(nil) }
            healthAction(title: "Visita", symbol: "cross.case.fill", accent: AppTheme.visit) { sheet = .visit(nil) }
            healthAction(title: "Peso", symbol: "scalemass", accent: AppTheme.weight) { sheet = .weight(nil) }
        }
    }

    private func healthAction(title: String, symbol: String, accent: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Space.xs) {
                Image(systemName: symbol)
                    .font(.body.weight(.bold))
                    .foregroundStyle(accent)
                    .frame(width: 38, height: 38)
                    .background(accent.opacity(0.16), in: Circle())
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(AppTheme.ink).lineLimit(2).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .padding(.vertical, AppTheme.Space.xs)
            .background(AppTheme.quickSurface, in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous).stroke(accent.opacity(0.28), lineWidth: 0.75))
        }
        .buttonStyle(QuickActionPressStyle())
        .accessibilityLabel("Añadir \(title.lowercased())")
    }

    private var vaccines: some View {
        collapsibleHealthSection(title: "Vacunas", symbol: "syringe", section: .vaccines, count: health.vaccines.count) {
            if health.vaccines.isEmpty {
                EmptyCareState(title: "Añade las vacunas para conservar su historial.", symbol: "syringe")
            } else {
                VStack(spacing: 0) {
                    let records = Array(health.vaccines.sorted { $0.dateAdministered > $1.dateAdministered }.prefix(3))
                    ForEach(records) { record in
                        let isHistorical = isHistoricalVaccine(record)
                        HealthRecordRow(
                            title: record.name,
                            subtitle: isHistorical ? AppFormat.date(record.dateAdministered) : vaccineSubtitle(record),
                            symbol: isHistorical ? "checkmark" : "syringe",
                            status: isHistorical ? nil : record.status().title,
                            statusColor: record.status().displayColor,
                            isHistorical: isHistorical
                        ) { sheet = .vaccine(record) }
                        if record.id != records.last?.id { Divider().overlay(AppTheme.border.opacity(0.5)) }
                    }
                }
            }
            HealthSectionActions(addTitle: "Añadir vacuna", onAdd: { sheet = .vaccine(nil) }, onHistory: { sheet = .history(.vaccines) })
        }
    }

    private var dewormings: some View {
        collapsibleHealthSection(title: "Desparasitación", symbol: "pills", section: .dewormings, count: health.dewormings.count) {
            VStack(spacing: 0) {
                ForEach(DewormingKind.allCases) { kind in
                    let accent = kind == .externalDeworming ? AppTheme.orange : AppTheme.green
                    if let record = health.dewormings.filter({ $0.kind == kind }).max(by: { $0.applicationDate < $1.applicationDate }) {
                        HealthRecordRow(title: kind.shortTitle, subtitle: dewormingSubtitle(record), symbol: kind.symbol, status: record.status().title, statusColor: record.status().displayColor, symbolAccent: accent) {
                            sheet = .deworming(record, kind)
                        }
                    } else {
                        Button { sheet = .deworming(nil, kind) } label: {
                            HStack(spacing: AppTheme.Space.md) {
                                CareSymbol(systemName: kind.symbol, accent: accent)
                                Text(kind.shortTitle).font(.body.weight(.medium)).foregroundStyle(AppTheme.ink)
                                Spacer(minLength: AppTheme.Space.sm)
                                Image(systemName: "plus").font(.subheadline.weight(.medium))
                            }
                            .padding(.vertical, AppTheme.Space.sm)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.green)
                        .accessibilityLabel("Añadir desparasitación \(kind.shortTitle.lowercased())")
                    }
                    if kind != DewormingKind.allCases.last { Divider().overlay(AppTheme.border.opacity(0.5)) }
                }
            }
            HealthSectionActions(addTitle: "Añadir aplicación", onAdd: { sheet = .deworming(nil, .internalDeworming) }, onHistory: { sheet = .history(.dewormings) })
        }
    }

    private var medications: some View {
        collapsibleHealthSection(title: "Medicación", symbol: "pills", section: .medications, count: health.medications.count) {
            let active = health.medications.filter { $0.isActive() }.sorted { $0.startDate > $1.startDate }
            if active.isEmpty {
                EmptyCareState(title: "No hay medicamentos activos", symbol: "pills", message: "Las medicaciones finalizadas quedan disponibles en el historial.")
            } else {
                ForEach(active.prefix(3)) { record in
                    HealthRecordRow(title: record.name, subtitle: String(localized: "Desde \(AppFormat.date(record.startDate))"), symbol: "pills", status: record.status().title, statusColor: record.status().displayColor) {
                        sheet = .medication(record)
                    }
                }
                if active.count > 3 {
                    Button("Ver los \(active.count) medicamentos activos") { sheet = .history(.medications) }
                }
            }
            HealthSectionActions(addTitle: "Añadir medicación", onAdd: { sheet = .medication(nil) }, onHistory: { sheet = .history(.medications) })
        }
    }

    private var visits: some View {
        collapsibleHealthSection(title: "Visitas veterinarias", symbol: "cross.case", section: .visits, count: health.visits.count) {
            if health.visits.isEmpty {
                EmptyCareState(title: "Guarda citas, valoraciones y documentos en un mismo lugar.", symbol: "cross.case")
            } else {
                VStack(spacing: 0) {
                    let records = Array(health.visits.sorted { $0.date > $1.date }.prefix(3))
                    ForEach(records) { visit in
                        HealthVisitRow(visit: visit) { sheet = .visitDetail(visit.id) }
                        if visit.id != records.last?.id { Divider().overlay(AppTheme.border.opacity(0.5)) }
                    }
                }
            }
            HealthSectionActions(addTitle: "Añadir visita", onAdd: { sheet = .visit(nil) }, onHistory: { sheet = .history(.visits) })
            if !health.documents.isEmpty {
                Button { sheet = .documents } label: {
                    Label("Documentos", systemImage: "paperclip")
                        .font(.subheadline.weight(.medium))
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.secondaryInk)
            }
        }
    }

    private var observations: some View {
        CareSection(title: "Observaciones de salud", style: .plain, symbol: "text.bubble") {
            let records = health.observations.filter { $0.context == .health || $0.context == .general }.sorted { $0.date > $1.date }
            if records.isEmpty {
                HStack(spacing: AppTheme.Space.sm) {
                    CareSymbol(systemName: "text.bubble", accent: AppTheme.blue, size: 32)
                    Text("Sin observaciones").font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                    Spacer(minLength: 0)
                    Button("Añadir", systemImage: "plus") { observation = nil; showObservation = true }
                        .buttonStyle(.bordered)
                }
                .frame(minHeight: 44)
            }
            ForEach(Array(records.prefix(showsAllObservations ? records.count : 2))) { record in
                HealthRecordRow(title: record.title, subtitle: observationSubtitle(record)) {
                    observationDetail = record
                }
            }
            if records.count > 2 {
                Button(showsAllObservations ? "Mostrar menos" : "Ver todas las observaciones") { showsAllObservations.toggle() }
            }
            if !records.isEmpty {
                Button("Añadir observación", systemImage: "plus") { observation = nil; showObservation = true }
                    .buttonStyle(.bordered)
            }
        }
    }

    private func observationSubtitle(_ record: PetObservation) -> String {
        let compact = record.body
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let limit = 96
        let preview = compact.count > limit ? String(compact.prefix(limit)) + "…" : compact
        return "\(AppFormat.date(record.date)) · \(preview)"
    }

    private func collapsibleHealthSection<Content: View>(
        title: LocalizedStringKey,
        symbol: String,
        section: HealthHistorySection,
        count: Int,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        CareSection(title: title, style: .compact, symbol: symbol) {
            DisclosureGroup(isExpanded: Binding(
                get: { expandedHistory.contains(section) },
                set: { expanded in
                    if expanded { expandedHistory.insert(section) }
                    else { expandedHistory.remove(section) }
                }
            )) {
                VStack(alignment: .leading, spacing: AppTheme.Space.md) { content() }
                    .padding(.top, AppTheme.Space.md)
            } label: {
                Text(count == 0 ? "Sin registros" : count == 1 ? "1 registro" : "\(count) registros")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryInk)
            }
        }
    }

    private func isHistoricalVaccine(_ record: VaccinationRecord) -> Bool {
        let name = record.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let hasNewerRecord = health.vaccines.contains {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == name && $0.dateAdministered > record.dateAdministered
        }
        return hasNewerRecord || record.nextDueDate == nil
    }

    private struct UpcomingCare {
        let title: String
        let date: Date
        let symbol: String
        let sheet: HealthSheet
    }

    private var nextCare: UpcomingCare? {
        let now = Date.now
        var items: [UpcomingCare] = []
        let latestVaccines = Dictionary(grouping: health.vaccines, by: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }).values.compactMap { $0.max { $0.dateAdministered < $1.dateAdministered } }
        for record in latestVaccines {
            if let date = record.nextDueDate, date > now {
                items.append(.init(title: record.name, date: date, symbol: "syringe", sheet: .vaccine(record)))
            }
        }
        for kind in DewormingKind.allCases {
            if let record = health.dewormings.filter({ $0.kind == kind }).max(by: { $0.applicationDate < $1.applicationDate }),
               let date = record.nextDueDate, date > now {
                items.append(.init(title: kind.title, date: date, symbol: kind.symbol, sheet: .deworming(record, kind)))
            }
        }
        for visit in health.visits {
            if visit.date > now { items.append(.init(title: visit.reason, date: visit.date, symbol: "cross.case", sheet: .visitDetail(visit.id))) }
            if let date = visit.followUpDate, date > now {
                items.append(.init(title: String(localized: "Seguimiento: \(visit.reason)"), date: date, symbol: "cross.case", sheet: .visitDetail(visit.id)))
            }
        }
        for record in health.medications where record.isActive(relativeTo: now) {
            if let date = record.endDate, date > now {
                items.append(.init(title: String(localized: "Fin de medicación: \(record.name)"), date: date, symbol: "pills", sheet: .medication(record)))
            }
        }
        return items.min { $0.date < $1.date }
    }
}

func vaccineSubtitle(_ record: VaccinationRecord) -> String {
    let applied = String(localized: "Administrada: \(AppFormat.date(record.dateAdministered))")
    guard let next = record.nextDueDate else { return applied }
    return applied + " · " + String(localized: "Próxima: \(AppFormat.date(next))")
}

func dewormingSubtitle(_ record: DewormingRecord) -> String {
    let applied = String(localized: "Última aplicación: \(AppFormat.date(record.applicationDate))")
    guard let next = record.nextDueDate else { return applied }
    return applied + " · " + String(localized: "Próxima: \(AppFormat.date(next))")
}

#Preview("Salud") {
    NavigationStack { HealthView() }.environment(PetPlanifyStore.preview())
}

#Preview("Salud sin registros") {
    NavigationStack { HealthView() }.environment(PetPlanifyStore.preview(empty: true))
}
