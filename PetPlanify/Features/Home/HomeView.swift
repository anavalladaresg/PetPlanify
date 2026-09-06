import SwiftUI

struct HomeView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var sheet: HomeSheet?
    @State private var setupExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private enum HomeSheet: String, Identifiable {
        case weight, visit, observation, trick, reminders, profile, food
        var id: Self { self }
    }
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            CarePage {
                profileHero(now: timeline.date)
                dashboardCards(now: timeline.date)
                CareSection(title: "Próximamente", style: .compact, symbol: "calendar") {
                    let upcoming = upcomingCare(at: timeline.date)
                    if upcoming.isEmpty {
                        EmptyCareState(title: "Por ahora, todo en orden", symbol: "calendar", message: "Aquí verás los próximos cuidados que hayas añadido.")
                            .padding(.vertical, AppTheme.Space.sm)
                    } else {
                        let visible = Array(upcoming.prefix(3))
                        VStack(spacing: 0) {
                            ForEach(Array(visible.enumerated()), id: \.element.id) { index, item in
                                upcomingTimelineRow(item, now: timeline.date, isLast: index == visible.count - 1)
                            }
                        }
                        if upcoming.count > 3 {
                            Button("Ver todos", systemImage: "arrow.right") { sheet = .reminders }
                                .buttonStyle(.bordered)
                        }
                    }
                }
                if !setupTasks.isEmpty {
                    setupProgressCard
                        .padding(AppTheme.Space.lg)
                        .background(AppTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous).stroke(AppTheme.border.opacity(0.7), lineWidth: 0.75))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: setupExpanded)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Registrar peso", systemImage: "scalemass") { sheet = .weight }.accessibilityIdentifier("weight.add")
                    Button("Añadir cita veterinaria", systemImage: "cross.case") { sheet = .visit }
                    Button("Añadir observación", systemImage: "square.and.pencil") { sheet = .observation }
                    Button("Añadir truco", systemImage: "pawprint") { sheet = .trick }
                } label: { Label("Añadir", systemImage: "plus") }.accessibilityIdentifier("home.add")
            }
        }
        .sheet(item: $sheet) { selected in
            switch selected {
            case .weight: WeightEditor()
            case .visit: VisitEditor()
            case .observation: ObservationEditor()
            case .trick: TrickLibraryView()
            case .reminders: CompactRemindersView()
            case .profile: ProfileEditor()
            case .food: FoodPlanEditor()
            }
        }
        .accessibilityIdentifier("home.screen")
    }

    @ViewBuilder
    private func profileHero(now: Date) -> some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(AppTheme.greenSoft.opacity(0.55))
                .frame(width: 190, height: 190)
                .blur(radius: 1)
                .offset(x: 54, y: -72)
                .accessibilityHidden(true)
            Circle()
                .fill(AppTheme.orangeSoft.opacity(0.65))
                .frame(width: 108, height: 108)
                .offset(x: -126, y: 122)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                HStack(alignment: .top, spacing: AppTheme.Space.md) {
                    VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                        Text(greeting(for: now))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.green)
                        Text(String(localized: "El cuidado de") + " " + petName)
                            .font(.title3.weight(.medium))
                            .fontDesign(.serif)
                            .foregroundStyle(AppTheme.ink)
                    }
                    Spacer(minLength: AppTheme.Space.sm)
                    Button { sheet = .profile } label: {
                        Image(systemName: "pencil")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.green)
                    .accessibilityLabel("Editar perfil")
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: AppTheme.Space.xl) {
                        avatar
                        profileSummary
                        Spacer(minLength: 0)
                    }
                    VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                        avatar
                        profileSummary
                    }
                }
            }
            .padding(AppTheme.Space.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [AppTheme.surfaceMuted, AppTheme.orangeSoft.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ), in: RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous).stroke(AppTheme.border.opacity(0.7), lineWidth: 0.75))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous))
        .shadow(color: AppTheme.shadow.opacity(0.06), radius: 12, y: 4)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func dashboardCards(now: Date) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: AppTheme.Space.md) {
                careScoreCard(now: now)
                    .frame(maxWidth: .infinity)
                todayCard(now: now)
                    .frame(maxWidth: .infinity)
            }
            .frame(minWidth: 620)
            VStack(spacing: AppTheme.Space.md) {
                careScoreCard(now: now)
                todayCard(now: now)
            }
        }
    }

    private func careScoreCard(now: Date) -> some View {
        let score = careScore(at: now)
        return VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            HStack(spacing: AppTheme.Space.sm) {
                CareSymbol(systemName: "sparkles", accent: AppTheme.green, size: 32)
                Text("Pet Care Score")
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                Spacer(minLength: 0)
            }
            HStack(spacing: AppTheme.Space.lg) {
                scoreRing(score: score)
                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text(scoreLabel(for: score))
                        .font(.title3.weight(.semibold))
                        .fontDesign(.serif)
                        .foregroundStyle(AppTheme.ink)
                    Text(scoreDetail(for: score))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(AppTheme.Space.xl)
        .background(
            LinearGradient(colors: [AppTheme.surface, AppTheme.greenSoft.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous).stroke(AppTheme.green.opacity(0.15), lineWidth: 0.75))
        .shadow(color: AppTheme.shadow.opacity(0.05), radius: 8, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pet Care Score: \(score) por ciento. \(scoreLabel(for: score)). \(scoreDetail(for: score))")
    }

    private func scoreRing(score: Int) -> some View {
        let progress = Double(score) / 100
        return ZStack {
            Circle()
                .stroke(AppTheme.greenSoft, lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppTheme.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)%")
                .font(.headline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(AppTheme.green)
        }
        .frame(width: 76, height: 76)
        .accessibilityHidden(true)
    }

    private func todayCard(now: Date) -> some View {
        let mealCount = store.snapshot.nutrition.plan?.meals.count ?? 0
        let remindersToday = store.snapshot.reminders.filter { !$0.isCompleted && Calendar.current.isDate($0.date, inSameDayAs: now) }.count
        let medicationCount = store.snapshot.health.medications.filter { $0.isActive(relativeTo: now) }.count
        let trickCount = store.snapshot.training.selectedTricks.count
        return VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            HStack(spacing: AppTheme.Space.sm) {
                CareSymbol(systemName: "sun.max", accent: AppTheme.orange, size: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hoy")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text(todayHeadline(mealCount: mealCount))
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                Spacer(minLength: 0)
            }
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], alignment: .leading, spacing: AppTheme.Space.lg) {
                todayMetric(value: mealCount, title: "comidas", symbol: "fork.knife", accent: AppTheme.orange)
                todayMetric(value: remindersToday, title: "pendientes", symbol: "calendar", accent: AppTheme.green)
                todayMetric(value: medicationCount, title: "medicación", symbol: "pills", accent: AppTheme.orange)
                todayMetric(value: trickCount, title: "trucos", symbol: "pawprint", accent: AppTheme.green)
            }
        }
        .padding(AppTheme.Space.xl)
        .background(
            LinearGradient(colors: [AppTheme.surface, AppTheme.orangeSoft.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous).stroke(AppTheme.orange.opacity(0.14), lineWidth: 0.75))
        .shadow(color: AppTheme.shadow.opacity(0.05), radius: 8, y: 3)
        .accessibilityElement(children: .contain)
    }

    private func todayMetric(value: Int, title: LocalizedStringKey, symbol: String, accent: Color) -> some View {
        HStack(spacing: AppTheme.Space.sm) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(accent)
                .frame(width: 20)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(value)")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.ink)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var setupProgressCard: some View {
        DisclosureGroup(isExpanded: $setupExpanded) {
            VStack(spacing: AppTheme.Space.sm) {
                ForEach(setupTasks, id: \.id) { item in
                    HStack(spacing: AppTheme.Space.sm) {
                        Button { openSetup(item.id) } label: {
                            Label(item.title, systemImage: setupSymbol(for: item.id))
                                .font(.body.weight(.medium))
                                .foregroundStyle(AppTheme.ink)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        Button("Omitir esta sugerencia", systemImage: "xmark") {
                            Task { _ = await store.update { $0.onboarding.dismissedSetupTasks.insert(item.id) } }
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .frame(minWidth: 44, minHeight: 44)
                        .foregroundStyle(AppTheme.secondaryInk)
                    }
                }
            }
            .padding(.top, AppTheme.Space.md)
        } label: {
            HStack(spacing: AppTheme.Space.md) {
                CareSymbol(systemName: "checklist", accent: AppTheme.green, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "Perfil de") + " " + petName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(setupProgressDetail)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                Spacer(minLength: AppTheme.Space.sm)
                Text("\(setupCompleted)/\(setupTotal)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.green)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func upcomingCare(at date: Date) -> [CareReminder] {
        ReminderEngine.upcoming(store.snapshot.reminders, now: date)
    }

    private func upcomingTimelineRow(_ item: CareReminder, now: Date, isLast: Bool) -> some View {
        let accent = item.relatedFeature == .health ? AppTheme.orange : AppTheme.green
        return Button {
            if item.relatedFeature == .general { sheet = .reminders }
            else { navigation.selection = AppSection(context: item.relatedFeature) }
        } label: {
            HStack(alignment: .top, spacing: AppTheme.Space.md) {
                VStack(spacing: 0) {
                    ZStack {
                        Circle().fill(accent.opacity(0.13))
                        Image(systemName: item.relatedFeature == .general ? "calendar" : AppSection(context: item.relatedFeature).icon)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(accent)
                    }
                    .frame(width: 32, height: 32)
                    if !isLast {
                        Rectangle()
                            .fill(AppTheme.border.opacity(0.7))
                            .frame(width: 1, height: 38)
                    }
                }
                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                        Text(item.title)
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryInk)
                            .accessibilityHidden(true)
                    }
                    Text(upcomingDateLabel(item.date, relativeTo: now))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                    Text(item.relatedFeature.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, AppTheme.Space.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private func upcomingDateLabel(_ date: Date, relativeTo now: Date) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        if Calendar.current.isDateInToday(date) { return String(localized: "Hoy · \(time)") }
        if Calendar.current.isDateInTomorrow(date) { return String(localized: "Mañana · \(time)") }
        return AppFormat.dateTime(date)
    }

    private var petName: String {
        let name = store.snapshot.pet.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? String(localized: "tu mascota") : name
    }

    private func greeting(for date: Date) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 6..<12: return String(localized: "Buenos días")
        case 12..<20: return String(localized: "Buenas tardes")
        default: return String(localized: "Buenas noches")
        }
    }

    private func todayHeadline(mealCount: Int) -> String {
        if mealCount == 0 { return String(localized: "Tu rutina, paso a paso") }
        if mealCount == 1 { return String(localized: "1 comida prevista") }
        return String(localized: "\(mealCount) comidas previstas")
    }

    private func careScore(at now: Date) -> Int {
        let pet = store.snapshot.pet
        let profileReady = !pet.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (!pet.breed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pet.ageMonths(at: now) != nil)
        let nutritionReady = store.snapshot.nutrition.plan != nil
        let healthReady = !store.snapshot.health.vaccines.isEmpty || !store.snapshot.health.visits.isEmpty
        let weightReady = store.currentWeight != nil
        let trainingReady = !store.snapshot.training.selectedTricks.isEmpty
        let reminders = store.snapshot.reminders
        let remindersReady = !reminders.isEmpty && !reminders.contains { $0.isOverdue(at: now) }
        let completed = [profileReady, nutritionReady, healthReady, weightReady, trainingReady, remindersReady].filter { $0 }.count
        return Int((Double(completed) / 6 * 100).rounded())
    }

    private func scoreLabel(for score: Int) -> String {
        if score >= 84 { return String(localized: "Todo al día") }
        if score >= 50 { return String(localized: "Buen camino") }
        return String(localized: "Primeros pasos")
    }

    private func scoreDetail(for score: Int) -> String {
        if score >= 84 { return String(localized: "La rutina está bien cubierta para") + " " + petName + "." }
        return String(localized: "Añade algunos datos para cuidar de") + " " + petName + " " + String(localized: "con más calma.")
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(AppTheme.greenSoft.opacity(0.82)).frame(width: 128, height: 128).offset(x: -6, y: 5)
            Circle().fill(AppTheme.orangeSoft.opacity(0.9)).frame(width: 62, height: 62).offset(x: 47, y: -38)
            if store.profilePhotoURL() != nil {
                PetAvatarView(size: 128, photoURL: store.profilePhotoURL())
                    .shadow(color: AppTheme.shadow.opacity(0.14), radius: 10, y: 5)
            } else {
                DogPoseIllustration(pose: .sitting).frame(width: 134, height: 116)
            }
        }.frame(width: 144, height: 136).accessibilityHidden(true)
    }
    private var profileSummary: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
            Text(petName).font(.system(.largeTitle, design: .serif, weight: .medium))
            Text([store.snapshot.pet.breed, store.snapshot.pet.ageDescription()].filter { !$0.isEmpty }.joined(separator: " · "))
                .font(.subheadline).foregroundStyle(AppTheme.secondaryInk).fixedSize(horizontal: false, vertical: true)
            if let weight = store.currentWeight {
                HStack(spacing: AppTheme.Space.sm) {
                    Image(systemName: "scalemass").font(.caption.weight(.medium)).foregroundStyle(AppTheme.green)
                    Text(AppFormat.weight(weight, unit: store.snapshot.preferences.weightUnit))
                        .font(.subheadline.weight(.medium)).monospacedDigit()
                }
                .padding(.horizontal, AppTheme.Space.sm)
                .padding(.vertical, 6)
                .background(AppTheme.surface.opacity(0.72), in: Capsule())
            }
        }.padding(.trailing, AppTheme.Space.md).accessibilityElement(children: .combine)
    }

    private var setupTotal: Int { 5 }
    private var setupCompleted: Int { max(0, setupTotal - setupTasks.count) }
    private var setupProgressDetail: String {
        if setupTasks.count == 1 { return String(localized: "1 sugerencia para completar") }
        return String(localized: "\(setupTasks.count) sugerencias para completar")
    }

    private func setupSymbol(for id: String) -> String {
        switch id {
        case "food": return "fork.knife"
        case "health": return "heart.fill"
        case "clinic": return "cross.case"
        case "tricks": return "pawprint.fill"
        default: return "bell"
        }
    }

    private var setupTasks: [(id: String, title: String)] {
        var tasks: [(String, String)] = []
        if store.snapshot.nutrition.plan == nil { tasks.append(("food", String(localized: "Configurar alimentación"))) }
        if store.snapshot.health.vaccines.isEmpty { tasks.append(("health", String(localized: "Añadir vacunas"))) }
        if store.snapshot.pet.primaryVeterinaryClinic?.isEmpty ?? true { tasks.append(("clinic", String(localized: "Añadir clínica veterinaria"))) }
        if store.snapshot.training.selectedTricks.isEmpty { tasks.append(("tricks", String(localized: "Elegir primeros trucos"))) }
        if store.snapshot.reminders.isEmpty { tasks.append(("reminders", String(localized: "Configurar recordatorios"))) }
        return tasks.filter { !store.snapshot.onboarding.dismissedSetupTasks.contains($0.0) }
    }
    private func openSetup(_ id: String) {
        switch id {
        case "food": sheet = .food
        case "health": navigation.selection = .health
        case "clinic": sheet = .profile
        case "tricks": sheet = .trick
        default: sheet = .reminders
        }
    }
}

#Preview { NavigationStack { HomeView() }.environment(PetPlanifyStore.preview()).environment(AppNavigation()) }
