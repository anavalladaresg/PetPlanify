import Charts
import SwiftUI

/// A read-only visual story built from the care records already stored locally.
/// It is presented from Inicio so the five primary areas remain stable.
struct EvolutionView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var period: EvolutionPeriod = .year

    private enum EvolutionPeriod: String, CaseIterable, Identifiable {
        case week, month, quarter, year, all
        var id: Self { self }
        var title: String {
            switch self {
            case .week: String(localized: "Semana")
            case .month: String(localized: "1 mes")
            case .quarter: String(localized: "3 meses")
            case .year: String(localized: "1 año")
            case .all: String(localized: "Todo")
            }
        }
        var days: Int? {
            switch self {
            case .week: 7
            case .month: 30
            case .quarter: 90
            case .year: 365
            case .all: nil
            }
        }
    }

    private var petName: String {
        let value = store.snapshot.pet.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? String(localized: "tu mascota") : value
    }

    private var weightRecords: [WeightRecord] {
        store.snapshot.health.weights.filter { includes($0.date) }.sorted { $0.date < $1.date }
    }
    private var trainingProgress: Int {
        let selected = store.snapshot.training.selectedTricks
        guard !selected.isEmpty else { return 0 }
        return Int((Double(selected.reduce(0) { $0 + $1.progress }) / Double(selected.count)).rounded())
    }
    private var masteredCount: Int { store.snapshot.training.selectedTricks.filter { $0.status == .mastered }.count }
    private var score: Int {
        let pet = store.snapshot.pet
        let reminders = store.snapshot.reminders
        let values = [
            !pet.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            store.snapshot.nutrition.plan != nil,
            !store.snapshot.health.vaccines.isEmpty || !store.snapshot.health.visits.isEmpty,
            store.currentWeight != nil,
            !store.snapshot.training.selectedTricks.isEmpty,
            !reminders.isEmpty && !reminders.contains { $0.isOverdue() }
        ]
        return Int((Double(values.filter { $0 }.count) / Double(values.count) * 100).rounded())
    }

    var body: some View {
        NavigationStack {
            CarePage {
                evolutionHero
                periodPicker
                metrics
                careScoreStory
                weightStory
                completedCareStory
                nutritionStory
                milestones
                lifeTimeline
            }
            .navigationTitle("Evolución")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .careSheet()
        .accessibilityIdentifier("evolution.screen")
    }

    private var evolutionHero: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: AppTheme.Space.xl) {
                evolutionHeroCopy
                Spacer(minLength: AppTheme.Space.lg)
                scoreRing
            }
            VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                evolutionHeroCopy
                scoreRing
            }
        }
        .padding(AppTheme.Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [AppTheme.surfaceMuted.opacity(0.58), AppTheme.sageSurface.opacity(0.38)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous).stroke(AppTheme.green.opacity(0.18), lineWidth: 0.75))
        .appSurface(cornerRadius: AppTheme.heroRadius, elevated: true)
        .accessibilityElement(children: .contain)
    }

    private var evolutionHeroCopy: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
            Text("La evolución de \(petName)")
                .font(.largeTitle.weight(.medium))
                .fontDesign(.serif)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Una lectura clara de su peso, cuidados y rutina.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
            Text(store.snapshot.pet.ageDescription())
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.green)
                .padding(.horizontal, AppTheme.Space.sm)
                .padding(.vertical, AppTheme.Space.xs)
                .background(AppTheme.greenSoft.opacity(0.72), in: Capsule())
        }
    }

    private var periodPicker: some View {
        Picker("Periodo", selection: $period) {
            ForEach(EvolutionPeriod.allCases) { option in Text(option.title).tag(option) }
        }
        .pickerStyle(.segmented)
        .accessibilityHint("Filtra las gráficas y el historial por periodo")
    }

    private var scoreRing: some View {
        ZStack {
            Circle().stroke(AppTheme.greenSoft, lineWidth: 8)
            Circle().trim(from: 0, to: Double(score) / 100)
                .stroke(AppTheme.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(score)%").font(.headline.weight(.semibold)).monospacedDigit()
                Text("al día").font(.caption2).foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .frame(width: 76, height: 76)
        .accessibilityLabel("Cuidado al día: \(score) por ciento")
    }

    private var metrics: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: AppTheme.Space.md), GridItem(.flexible(), spacing: AppTheme.Space.md)], spacing: AppTheme.Space.md) {
            evolutionMetric(value: store.currentWeight.map { AppFormat.weight($0, unit: store.snapshot.preferences.weightUnit) } ?? "—", title: "Peso actual", symbol: "scalemass", accent: AppTheme.green)
            evolutionMetric(value: "\(store.snapshot.health.vaccines.count)", title: "Vacunas", symbol: "syringe", accent: AppTheme.orange)
            evolutionMetric(value: "\(store.snapshot.training.selectedTricks.count)", title: "Trucos", symbol: "pawprint.fill", accent: AppTheme.green)
            evolutionMetric(value: store.snapshot.nutrition.plan.map { "\($0.meals.count)" } ?? "—", title: "Comidas al día", symbol: "fork.knife", accent: AppTheme.orange)
        }
    }

    private func evolutionMetric(value: String, title: LocalizedStringKey, symbol: String, accent: Color) -> some View {
        HStack(spacing: AppTheme.Space.md) {
            CareSymbol(systemName: symbol, accent: accent, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.title2.weight(.semibold)).monospacedDigit()
                Text(title).font(.caption).foregroundStyle(AppTheme.secondaryInk)
            }
            Spacer(minLength: 0)
        }
        .padding(AppTheme.Space.lg)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
        .shadow(color: AppTheme.highlight.opacity(0.72), radius: 7, x: -3, y: -3)
        .shadow(color: AppTheme.shadow.opacity(0.18), radius: 7, x: 3, y: 4)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous).stroke(AppTheme.border.opacity(0.7), lineWidth: 0.75))
    }

    private var weightStory: some View {
        CareSection(title: "Evolución del peso", style: .compact, symbol: "chart.xyaxis.line") {
            if weightRecords.isEmpty {
                EmptyCareState(title: "Aún no hay una historia de peso", symbol: "scalemass", message: "Registra varios pesos para ver cómo cambia con el tiempo.", illustration: .scale)
            } else {
                Chart {
                    ForEach(weightRecords) { record in
                        AreaMark(x: .value("Fecha", record.date), y: .value("Peso", store.snapshot.preferences.weightUnit.fromKilograms(record.weight)))
                            .foregroundStyle(AppTheme.green.opacity(0.11))
                            .interpolationMethod(.monotone)
                        LineMark(x: .value("Fecha", record.date), y: .value("Peso", store.snapshot.preferences.weightUnit.fromKilograms(record.weight)))
                            .foregroundStyle(AppTheme.green)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .interpolationMethod(.monotone)
                        PointMark(x: .value("Fecha", record.date), y: .value("Peso", store.snapshot.preferences.weightUnit.fromKilograms(record.weight)))
                            .foregroundStyle(AppTheme.green)
                            .symbolSize(24)
                            .accessibilityLabel(AppFormat.date(record.date))
                            .accessibilityValue(AppFormat.weight(record.weight, unit: store.snapshot.preferences.weightUnit))
                    }
                }
                .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in AxisGridLine().foregroundStyle(AppTheme.border.opacity(0.3)); AxisValueLabel().font(.caption2) } }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) { _ in AxisValueLabel(format: .dateTime.day().month(.abbreviated)).font(.caption2) } }
                .frame(height: 170)
                .accessibilityLabel("Evolución del peso de \(petName)")
            }
        }
    }

    private var careScoreStory: some View {
        CareSection(title: "Care Score", style: .compact, symbol: "chart.line.uptrend.xyaxis") {
            if scoreHistory.count < 2 {
                VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                    ProgressView(value: Double(score), total: 100).tint(AppTheme.green)
                    Text("La tendencia aparecerá cuando haya más hitos de cuidado.")
                        .font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                }
            } else {
                Chart(scoreHistory) { point in
                    AreaMark(x: .value("Fecha", point.date), y: .value("Care Score", point.score))
                        .foregroundStyle(AppTheme.green.opacity(0.10))
                        .interpolationMethod(.monotone)
                    LineMark(x: .value("Fecha", point.date), y: .value("Care Score", point.score))
                        .foregroundStyle(AppTheme.green)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .interpolationMethod(.monotone)
                    PointMark(x: .value("Fecha", point.date), y: .value("Care Score", point.score))
                        .foregroundStyle(AppTheme.green)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis { AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in AxisGridLine().foregroundStyle(AppTheme.border.opacity(0.3)); AxisValueLabel { if let number = value.as(Int.self) { Text("\(number)%") } } } }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) { _ in AxisValueLabel(format: .dateTime.day().month(.abbreviated)).font(.caption2) } }
                .frame(height: 170)
                .accessibilityLabel("Evolución del Care Score de \(petName)")
            }
        }
    }

    private var completedCareStory: some View {
        CareSection(title: "Vacunas y cuidados", style: .compact, symbol: "checkmark.circle.fill") {
            if completedCareCounts.allSatisfy({ $0.count == 0 }) {
                EmptyCareState(title: "Sin cuidados en este periodo", symbol: "calendar.badge.plus", message: "Cambia el periodo o registra un cuidado de salud.")
            } else {
                Chart(completedCareCounts) { item in
                    BarMark(x: .value("Tipo", item.title), y: .value("Completados", item.count))
                        .foregroundStyle(item.accent.gradient)
                        .cornerRadius(5)
                        .annotation(position: .top) { Text("\(item.count)").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk) }
                }
                .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) }
                .frame(height: 170)
                .accessibilityLabel("Cuidados de salud completados")
            }
        }
    }

    @ViewBuilder
    private var nutritionStory: some View {
        if let plan = store.snapshot.nutrition.plan {
            CareSection(title: "Alimentación", style: .compact, symbol: "fork.knife") {
                if plan.meals.isEmpty {
                    Text("El plan no tiene horarios configurados.").font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                } else {
                    Chart(plan.meals) { meal in
                        BarMark(x: .value("Hora", meal.time.formatted(date: .omitted, time: .shortened)), y: .value("Gramos", meal.amountGrams))
                            .foregroundStyle(AppTheme.orange.gradient)
                            .cornerRadius(5)
                    }
                    .chartYAxisLabel("g")
                    .frame(height: 160)
                    .accessibilityLabel("Distribución diaria de alimentación")
                    Text("\(plan.dailyAmountGrams.formatted()) g al día · \(plan.meals.count) toma\(plan.meals.count == 1 ? "" : "s")")
                        .font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                }
            }
        }
    }

    private var milestones: some View {
        CareSection(title: "Hitos de cuidado", style: .highlighted, symbol: "sparkles") {
            if masteredCount == 0 && store.snapshot.health.vaccines.isEmpty && store.snapshot.health.visits.isEmpty {
                EmptyCareState(title: "Los primeros hitos están por llegar", symbol: "star", message: "Cuando registres un cuidado o domines un truco aparecerá aquí.", illustration: .clicker)
            } else {
                VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                    if masteredCount > 0 { milestoneRow("\(masteredCount) trucos dominados", symbol: "checkmark.seal.fill", accent: AppTheme.green) }
                    if !store.snapshot.health.vaccines.isEmpty { milestoneRow("Historial de vacunas iniciado", symbol: "syringe.fill", accent: AppTheme.orange) }
                    if !store.snapshot.health.visits.isEmpty { milestoneRow("Primera visita registrada", symbol: "cross.case.fill", accent: AppTheme.green) }
                    if trainingProgress > 0 { milestoneRow("Entrenamiento al \(trainingProgress)%", symbol: "chart.line.uptrend.xyaxis", accent: AppTheme.green) }
                }
            }
        }
    }

    private func milestoneRow(_ title: String, symbol: String, accent: Color) -> some View {
        HStack(spacing: AppTheme.Space.md) {
            Image(systemName: symbol).foregroundStyle(accent).frame(width: 24)
            Text(title).font(.body.weight(.medium))
            Spacer()
            Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(accent).accessibilityHidden(true)
        }
        .frame(minHeight: 44)
    }

    private var lifeTimeline: some View {
        CareSection(title: "Línea de vida", style: .plain, symbol: "calendar.badge.clock") {
            if timelineEvents.isEmpty {
                EmptyCareState(title: "Tu historia empezará aquí", symbol: "calendar", message: "Los cuidados que registres aparecerán ordenados por fecha.", illustration: .calendar)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(timelineEvents.enumerated()), id: \.element.id) { index, event in
                        timelineRow(event, isLast: index == timelineEvents.count - 1)
                    }
                }
            }
        }
    }

    private func timelineRow(_ event: EvolutionEvent, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Space.md) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(event.accent.opacity(0.13))
                    Image(systemName: event.symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(event.accent)
                }
                .frame(width: 28, height: 28)
                if !isLast { Rectangle().fill(AppTheme.border).frame(width: 1, height: 34) }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title).font(.body.weight(.medium))
                Text(event.detail).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                Text(AppFormat.date(event.date)).font(.caption).foregroundStyle(event.accent)
            }
            .padding(.bottom, isLast ? 0 : AppTheme.Space.lg)
        }
        .accessibilityElement(children: .combine)
    }

    private var timelineEvents: [EvolutionEvent] {
        var events: [EvolutionEvent] = []
        if let birthDate = store.snapshot.pet.birthDate {
            events.append(EvolutionEvent(id: "birth", date: birthDate, title: "Nació \(petName)", detail: store.snapshot.pet.ageDescription(), symbol: "birthday.cake", accent: AppTheme.orange))
        }
        if let plan = store.snapshot.nutrition.plan {
            events.append(EvolutionEvent(id: "food-\(plan.id)", date: plan.startDate, title: "Plan de alimentación", detail: plan.product.name, symbol: "fork.knife", accent: AppTheme.orange))
        }
        events += weightRecords.map { weight in
            EvolutionEvent(id: "weight-\(weight.id)", date: weight.date, title: "Peso registrado", detail: AppFormat.weight(weight.weight, unit: store.snapshot.preferences.weightUnit), symbol: "scalemass", accent: AppTheme.green)
        }
        events += store.snapshot.health.vaccines.map { vaccine in
            EvolutionEvent(id: "vaccine-\(vaccine.id)", date: vaccine.dateAdministered, title: vaccine.name, detail: "Vacuna registrada", symbol: "syringe", accent: AppTheme.green)
        }
        events += store.snapshot.health.dewormings.map { deworming in
            EvolutionEvent(id: "deworming-\(deworming.id)", date: deworming.applicationDate, title: deworming.kind.title, detail: deworming.productName ?? "Cuidado registrado", symbol: deworming.kind.symbol, accent: AppTheme.orange)
        }
        events += store.snapshot.health.medications.map { medication in
            EvolutionEvent(id: "medication-\(medication.id)", date: medication.startDate, title: medication.name, detail: "Medicación iniciada", symbol: "pills", accent: AppTheme.orange)
        }
        events += store.snapshot.health.visits.map { visit in
            EvolutionEvent(id: "visit-\(visit.id)", date: visit.date, title: "Visita veterinaria", detail: visit.reason, symbol: "cross.case", accent: AppTheme.green)
        }
        events += store.snapshot.health.observations.map { observation in
            EvolutionEvent(id: "observation-\(observation.id)", date: observation.date, title: observation.title, detail: observation.context.title, symbol: "square.and.pencil", accent: AppTheme.green)
        }
        events += store.snapshot.training.selectedTricks.map { trick in
            EvolutionEvent(id: "trick-\(trick.id)", date: trick.addedAt, title: store.snapshot.training.definition(for: trick.trickID)?.name ?? "Truco", detail: trick.status.title, symbol: "pawprint", accent: AppTheme.green)
        }
        return events.filter { includes($0.date) }.sorted { $0.date > $1.date }.prefix(12).map { $0 }
    }

    private func includes(_ date: Date, now: Date = .now) -> Bool {
        guard let days = period.days, let start = Calendar.current.date(byAdding: .day, value: -days, to: now) else { return true }
        return date >= start && date <= now
    }

    private var scoreHistory: [EvolutionScorePoint] {
        var milestones: [(Date, Int)] = [(store.snapshot.pet.createdAt, 1)]
        if let plan = store.snapshot.nutrition.plan { milestones.append((plan.startDate, 1)) }
        let healthDates = store.snapshot.health.vaccines.map(\.dateAdministered) + store.snapshot.health.visits.map(\.date) + store.snapshot.health.medications.map(\.startDate)
        if let first = healthDates.min() { milestones.append((first, 1)) }
        if let first = store.snapshot.health.weights.map(\.date).min() { milestones.append((first, 1)) }
        if let first = store.snapshot.training.selectedTricks.map(\.addedAt).min() { milestones.append((first, 1)) }
        if let first = store.snapshot.reminders.map(\.date).min() { milestones.append((first, 1)) }
        var value = 0
        let all = milestones.sorted { $0.0 < $1.0 }.map { date, increment -> EvolutionScorePoint in
            value = min(6, value + increment)
            return EvolutionScorePoint(date: date, score: Int((Double(value) / 6 * 100).rounded()))
        }
        guard let days = period.days, let start = Calendar.current.date(byAdding: .day, value: -days, to: .now) else { return all }
        let baseline = all.last { $0.date < start }.map { EvolutionScorePoint(date: start, score: $0.score) }
        return [baseline].compactMap { $0 } + all.filter { $0.date >= start && $0.date <= .now }
    }

    private var completedCareCounts: [EvolutionCareCount] {
        let health = store.snapshot.health
        return [
            EvolutionCareCount(title: String(localized: "Vacunas"), count: health.vaccines.filter { includes($0.dateAdministered) }.count, accent: AppTheme.green),
            EvolutionCareCount(title: String(localized: "Desparasitación"), count: health.dewormings.filter { includes($0.applicationDate) }.count, accent: AppTheme.orange),
            EvolutionCareCount(title: String(localized: "Medicación"), count: health.medications.filter { includes($0.startDate) }.count, accent: AppTheme.training),
            EvolutionCareCount(title: String(localized: "Visitas"), count: health.visits.filter { $0.date <= .now && includes($0.date) }.count, accent: AppTheme.health)
        ]
    }
}

private struct EvolutionEvent: Identifiable {
    let id: String
    let date: Date
    let title: String
    let detail: String
    let symbol: String
    let accent: Color
}

private struct EvolutionScorePoint: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
}

private struct EvolutionCareCount: Identifiable {
    var id: String { title }
    let title: String
    let count: Int
    let accent: Color
}

#Preview("Evolución") { EvolutionView().environment(PetPlanifyStore.preview()) }
