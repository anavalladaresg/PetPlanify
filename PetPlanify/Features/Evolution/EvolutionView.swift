import Charts
import SwiftUI

/// A read-only visual story built from the care records already stored locally.
/// It is presented from Inicio so the five primary areas remain stable.
struct EvolutionView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var petName: String {
        let value = store.snapshot.pet.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? String(localized: "tu mascota") : value
    }

    private var weightRecords: [WeightRecord] { store.snapshot.health.weights.sorted { $0.date < $1.date } }
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
                metrics
                weightStory
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
        HStack(alignment: .center, spacing: AppTheme.Space.xl) {
            DogPoseIllustration(pose: .coming)
                .frame(width: 142, height: 116)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                Text("La historia de \(petName)")
                    .font(.largeTitle.weight(.medium))
                    .fontDesign(.serif)
                    .foregroundStyle(AppTheme.ink)
                Text("Pequeños cuidados construyen una vida más tranquila.")
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
            Spacer(minLength: 0)
            scoreRing
        }
        .padding(AppTheme.Space.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [AppTheme.surfaceMuted, AppTheme.sageSurface.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous).stroke(AppTheme.green.opacity(0.18), lineWidth: 0.75))
        .appSurface(cornerRadius: AppTheme.heroRadius, elevated: true)
        .accessibilityElement(children: .contain)
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
                Circle().fill(event.accent).frame(width: 10, height: 10).padding(5)
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
        events += store.snapshot.health.vaccines.map { vaccine in
            EvolutionEvent(id: "vaccine-\(vaccine.id)", date: vaccine.dateAdministered, title: vaccine.name, detail: "Vacuna registrada", symbol: "syringe", accent: AppTheme.green)
        }
        events += store.snapshot.health.visits.map { visit in
            EvolutionEvent(id: "visit-\(visit.id)", date: visit.date, title: "Visita veterinaria", detail: visit.reason, symbol: "cross.case", accent: AppTheme.green)
        }
        events += store.snapshot.training.selectedTricks.map { trick in
            EvolutionEvent(id: "trick-\(trick.id)", date: trick.addedAt, title: store.snapshot.training.definition(for: trick.trickID)?.name ?? "Truco", detail: trick.status.title, symbol: "pawprint", accent: AppTheme.green)
        }
        return events.sorted { $0.date > $1.date }.prefix(8).map { $0 }
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

#Preview("Evolución") { EvolutionView().environment(PetPlanifyStore.preview()) }
