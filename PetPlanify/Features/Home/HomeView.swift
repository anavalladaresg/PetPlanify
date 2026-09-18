import SwiftUI

struct HomeView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("petplanify.apple.displayName") private var appleDisplayName = ""
    @State private var sheet: HomeSheet?
    @State private var setupExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private enum OnboardingStep: Int, CaseIterable {
        case food, health, reminders

        var title: String {
            switch self {
            case .food: return String(localized: "Alimentación")
            case .health: return String(localized: "Salud")
            case .reminders: return String(localized: "Próximos eventos")
            }
        }
        var actionTitle: String {
            switch self {
            case .food: return String(localized: "Configura sus comidas")
            case .health: return String(localized: "Completa sus datos de salud")
            case .reminders: return String(localized: "Activa sus recordatorios")
            }
        }
        var message: String {
            switch self {
            case .food: return String(localized: "Define horarios y cantidades para empezar.")
            case .health: return String(localized: "Añade vacunas, peso o su clínica veterinaria.")
            case .reminders: return String(localized: "Recibe avisos para no olvidar sus cuidados.")
            }
        }
        var symbol: String {
            switch self {
            case .food: return "fork.knife"
            case .health: return "cross.case.fill"
            case .reminders: return "bell.fill"
            }
        }
        var accent: Color {
            switch self {
            case .food: return AppTheme.orange
            case .health: return AppTheme.blue
            case .reminders: return AppTheme.green
            }
        }
    }
    private enum HomeSheet: String, Identifiable {
        case weight, visit, observation, trick, reminders, profile, food, evolution
        var id: Self { self }
    }
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            CarePage {
                profileHero(now: timeline.date)
                    .accessibilitySortPriority(10)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: AppTheme.Space.lg) {
                        nextStepCard(now: timeline.date).frame(maxWidth: .infinity, alignment: .top).accessibilitySortPriority(9)
                        careScoreCard(now: timeline.date).frame(maxWidth: .infinity, minHeight: 204, alignment: .top).accessibilitySortPriority(8)
                    }.frame(minWidth: 620)
                    VStack(spacing: AppTheme.Space.lg) {
                        nextStepCard(now: timeline.date).accessibilitySortPriority(9)
                        careScoreCard(now: timeline.date).accessibilitySortPriority(8)
                    }
                }
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: AppTheme.Space.lg) {
                        upcomingCard(now: timeline.date).frame(maxWidth: .infinity).accessibilitySortPriority(6)
                        if !isInitialProfile && !setupTasks.isEmpty { setupProgressCard.frame(maxWidth: .infinity).accessibilitySortPriority(5) }
                    }.frame(minWidth: 620)
                    VStack(spacing: AppTheme.Space.lg) {
                        upcomingCard(now: timeline.date).accessibilitySortPriority(6)
                        if !isInitialProfile && !setupTasks.isEmpty { setupProgressCard.accessibilitySortPriority(5) }
                    }
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
            case .evolution: EvolutionView()
            }
        }
        .accessibilityIdentifier("home.screen")
    }

    @ViewBuilder
    private func profileHero(now: Date) -> some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .center, spacing: AppTheme.Space.lg) {
                avatar
                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    HStack(spacing: AppTheme.Space.sm) {
                        Text(greeting(for: now))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.green)
                        Spacer(minLength: 0)
                        Button { sheet = .profile } label: {
                            Image(systemName: "pencil")
                                .font(.caption.weight(.semibold))
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.green)
                        .background(AppTheme.highlight.opacity(0.42), in: Circle())
                        .accessibilityLabel("Editar perfil")
                    }
                    Text(petName)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                    if horizontalSizeClass == .compact {
                        VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                            if store.snapshot.pet.breed.isEmpty {
                                HStack(spacing: AppTheme.Space.md) {
                                    heroAgeBadge
                                    heroWeightBadge
                                }
                            } else {
                                HStack(spacing: AppTheme.Space.md) {
                                    heroBreedBadge
                                    heroAgeBadge
                                }
                                heroWeightBadge
                            }
                        }
                    } else {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: AppTheme.Space.sm) {
                                heroIdentityBadges
                                heroWeightBadge
                            }
                                .fixedSize(horizontal: true, vertical: false)
                            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                                heroIdentityBadges
                                heroWeightBadge
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(AppTheme.Space.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [AppTheme.heroSurface, AppTheme.greenSoft.opacity(0.86), AppTheme.orangeSoft.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ), in: RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous).stroke(AppTheme.border.opacity(0.7), lineWidth: 0.75))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous))
        .shadow(color: AppTheme.shadow.opacity(0.08), radius: 16, y: 6)
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
        return VStack(alignment: .leading, spacing: AppTheme.Space.md) {
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
                    if score < 84 {
                        StatusBadge(title: isInitialProfile ? "Estimación inicial" : "En progreso", symbol: "clock.fill", tint: AppTheme.green)
                    }
                }
                Spacer(minLength: 0)
            }
            Button("Ver evolución", systemImage: "chart.xyaxis.line") { sheet = .evolution }
                .buttonStyle(.borderless)
                .foregroundStyle(AppTheme.green)
                .frame(minHeight: 44, alignment: .leading)
                .accessibilityIdentifier("home.evolution")
        }
        .padding(AppTheme.Space.xl)
        .background(
            LinearGradient(colors: [AppTheme.scoreSurface, AppTheme.greenSoft.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous).stroke(AppTheme.green.opacity(0.15), lineWidth: 0.75))
        .shadow(color: AppTheme.shadow.opacity(0.07), radius: 12, y: 5)
        .accessibilityIdentifier("home.careScore")
    }

    @ViewBuilder
    private func nextStepCard(now: Date) -> some View {
        if let step = onboardingStep {
            onboardingCard(step: step)
        }
    }

    private func onboardingCard(step: OnboardingStep) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            HStack {
                CareSymbol(systemName: step.symbol, accent: step.accent, size: 46)
                Spacer()
                StatusBadge(title: "Paso \(step.rawValue + 1) de 3", symbol: "arrow.right.circle.fill", tint: step.accent)
            }
            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text("Siguiente paso").font(.caption.weight(.bold)).textCase(.uppercase).tracking(1.1).foregroundStyle(AppTheme.orange)
                Text(step.actionTitle).font(.title3.weight(.bold)).foregroundStyle(AppTheme.ink)
                Text(step.message).font(.subheadline).foregroundStyle(AppTheme.secondaryInk).lineLimit(1)
            }
            onboardingStepper(active: step)
            Button { openSetup(step) } label: {
                Label("Empezar ahora", systemImage: "arrow.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(AppTheme.orange, in: Capsule())
            }
            .buttonStyle(QuickActionPressStyle())
        }
        .padding(AppTheme.Space.md)
        .frame(maxWidth: .infinity, minHeight: 166, alignment: .topLeading)
        .background(AppTheme.actionSurface, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous).stroke(AppTheme.orange.opacity(0.24), lineWidth: 0.8))
        .shadow(color: AppTheme.shadow.opacity(0.10), radius: 9, y: 4)
        .accessibilityIdentifier("home.nextStep")
    }

    private func completedRoutineCard(now: Date) -> some View {
        let next = upcomingCare(at: now).first
        return VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            HStack(spacing: AppTheme.Space.md) {
                CareSymbol(systemName: "checkmark.seal.fill", accent: AppTheme.green, size: 42)
                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text("La rutina de \(petName) está lista")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                    Text(next.map { "Próximo cuidado: \($0.title)." } ?? "Todo al día. Sigue registrando sus cuidados habituales.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                }
                Spacer(minLength: 0)
                StatusBadge(title: "Rutina activa", symbol: "checkmark.circle.fill", tint: AppTheme.green)
            }
            Button(next == nil ? "Ver evolución" : "Ver próximo cuidado", systemImage: next == nil ? "chart.xyaxis.line" : "arrow.right") {
                if let next {
                    if next.relatedFeature == .general { sheet = .reminders }
                    else { navigation.selection = AppSection(context: next.relatedFeature) }
                } else {
                    sheet = .evolution
                }
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.green)
        }
        .padding(AppTheme.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.scoreSurface, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous).stroke(AppTheme.green.opacity(0.18), lineWidth: 0.8))
        .shadow(color: AppTheme.shadow.opacity(0.10), radius: 10, y: 5)
        .accessibilityIdentifier("home.nextStep")
    }

    private func onboardingStepper(active: OnboardingStep?) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                VStack(spacing: AppTheme.Space.xs) {
                    ZStack {
                        Circle()
                            .fill(step.rawValue <= (active?.rawValue ?? 3) ? AppTheme.orange : AppTheme.surfaceMuted)
                            .frame(width: 36, height: 36)
                        Image(systemName: step.rawValue < (active?.rawValue ?? 3) ? "checkmark" : step.symbol)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(step == active || step.rawValue < (active?.rawValue ?? 3) ? .white : AppTheme.secondaryInk)
                    }
                    Text(step.title)
                        .font(.caption2.weight(step == active ? .bold : .medium))
                        .foregroundStyle(step == active ? AppTheme.ink : AppTheme.secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(step.rawValue < (active?.rawValue ?? 3) ? "Completado" : step == active ? "En curso" : "Después")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(step == active ? AppTheme.orange : AppTheme.secondaryInk)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Paso \(step.rawValue + 1) de 3, \(step.title), \(step.rawValue < (active?.rawValue ?? 3) ? "completado" : step == active ? "en curso" : "pendiente")")
                if step != .reminders {
                    Rectangle()
                        .fill(step.rawValue <= (active?.rawValue ?? 3) ? AppTheme.orange : AppTheme.border.opacity(0.72))
                        .frame(maxWidth: .infinity)
                        .frame(height: 2)
                        .padding(.horizontal, AppTheme.Space.xs)
                        .padding(.top, 17)
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: active)
    }

    private func routineCard(now: Date) -> some View {
        let mealCount = store.snapshot.nutrition.plan?.meals.count ?? 0
        let reminders = store.snapshot.reminders.filter { !$0.isCompleted && Calendar.current.isDate($0.date, inSameDayAs: now) }.count
        let medication = store.snapshot.health.medications.filter { $0.isActive(relativeTo: now) }.count
        let tricks = store.snapshot.training.selectedTricks.count
        return VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text("Acciones rápidas").font(.title3.weight(.bold)).foregroundStyle(AppTheme.ink)
                    Text("Registra un cuidado en un toque").font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                }
                Spacer()
                Image(systemName: "sun.max.fill").font(.title2).foregroundStyle(AppTheme.orange)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppTheme.Space.sm) {
                    quickAction(title: "Comida", status: mealCount == 0 ? "Añadir comida" : "Plan configurado", symbol: "fork.knife", accent: AppTheme.orange) { sheet = .food }
                    quickAction(title: "Pendiente", status: reminders == 0 ? "Nada pendiente" : "\(reminders) pendiente\(reminders == 1 ? "" : "s")", symbol: "calendar", accent: AppTheme.blue) { sheet = .reminders }
                    quickAction(title: "Salud", status: medication == 0 ? "Registrar salud" : "\(medication) activa", symbol: "heart.text.square.fill", accent: AppTheme.health) { navigation.selection = .health }
                    quickAction(title: "Juego", status: tricks == 0 ? "Añadir juego" : "\(tricks) trucos", symbol: "pawprint.fill", accent: AppTheme.training) { sheet = .trick }
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Space.sm) {
                    quickAction(title: "Comida", status: mealCount == 0 ? "Añadir comida" : "Plan configurado", symbol: "fork.knife", accent: AppTheme.orange) { sheet = .food }
                    quickAction(title: "Pendiente", status: reminders == 0 ? "Nada pendiente" : "\(reminders) pendiente\(reminders == 1 ? "" : "s")", symbol: "calendar", accent: AppTheme.blue) { sheet = .reminders }
                    quickAction(title: "Salud", status: medication == 0 ? "Registrar salud" : "\(medication) activa", symbol: "heart.text.square.fill", accent: AppTheme.health) { navigation.selection = .health }
                    quickAction(title: "Juego", status: tricks == 0 ? "Añadir juego" : "\(tricks) trucos", symbol: "pawprint.fill", accent: AppTheme.training) { sheet = .trick }
                }
            }
        }
        .padding(AppTheme.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(elevated: true)
    }

    private func quickAction(title: LocalizedStringKey, status: String, symbol: String, accent: Color, action: @escaping () -> Void) -> some View {
        QuickActionButton(title: title, subtitle: status, symbol: symbol, accent: accent, action: action)
    }

    private func upcomingCard(now: Date) -> some View {
        CareSection(title: "Próximamente", style: .compact, symbol: "calendar") {
            let upcoming = upcomingCare(at: now)
            if upcoming.isEmpty {
                EmptyCareState(title: "Por ahora, todo en orden", symbol: "calendar.badge.checkmark", message: "Aquí aparecerán los próximos cuidados que añadas.")
            } else {
                let visible = Array(upcoming.prefix(3))
                VStack(spacing: 0) {
                    ForEach(Array(visible.enumerated()), id: \.element.id) { index, item in
                        upcomingTimelineRow(item, now: now, isLast: index == visible.count - 1)
                    }
                }
                if upcoming.count > 3 { Button("Ver todos", systemImage: "arrow.right") { sheet = .reminders }.buttonStyle(.borderless).foregroundStyle(AppTheme.green) }
            }
        }
    }

    private func scoreRing(score: Int) -> some View {
        let progress = Double(score) / 100
        return ZStack {
            Circle()
                .stroke(AppTheme.greenSoft.opacity(0.72), lineWidth: 11)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppTheme.green, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)%")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppTheme.green)
        }
        .frame(width: 108, height: 108)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(score) por ciento")
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
        .padding(AppTheme.Space.lg)
        .background(
            LinearGradient(colors: [AppTheme.surface.opacity(0.62), AppTheme.orangeSoft.opacity(0.38)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous).stroke(AppTheme.orange.opacity(0.14), lineWidth: 0.75))
        .shadow(color: AppTheme.shadow.opacity(0.07), radius: 12, y: 5)
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
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
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
                    VStack(alignment: .trailing, spacing: AppTheme.Space.xs) {
                        Text("\(setupCompleted) de \(setupTotal)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.green)
                        ProgressView(value: Double(setupCompleted), total: Double(setupTotal))
                            .tint(AppTheme.green)
                            .frame(width: 86)
                    }
                }
            }
            if let task = setupTasks.first {
                Button("Completar: \(task.title)", systemImage: setupSymbol(for: task.id)) {
                    openSetup(task.id)
                }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.green)
            }
        }
        .padding(AppTheme.Space.lg)
        .appSurface(cornerRadius: AppTheme.compactRadius)
        .accessibilityElement(children: .contain)
    }

    private func upcomingCare(at date: Date) -> [CareReminder] {
        ReminderEngine.upcoming(store.snapshot.reminders.filter { $0.sourceKey != nil }, now: date)
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
                    StatusBadge(title: item.relatedFeature.title, symbol: item.relatedFeature == .health ? "heart.text.square.fill" : "calendar", tint: accent)
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
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) { return String(localized: "Hoy · \(time)") }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return String(localized: "Mañana · \(time)")
        }
        let months = calendar.dateComponents([.month], from: now, to: date).month ?? 0
        if months >= 2 {
            return String(localized: "Dentro de \(months) meses") + " · " + AppFormat.dateTime(date)
        }
        return AppFormat.dateTime(date)
    }

    private var petName: String {
        let name = store.snapshot.pet.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? String(localized: "tu mascota") : name
    }

    private var isInitialProfile: Bool {
        let hasNutrition = store.snapshot.nutrition.plan != nil
        let hasWeight = store.currentWeight != nil
        let activityCount = store.snapshot.health.vaccines.count
            + store.snapshot.health.visits.count
            + store.snapshot.health.medications.count
            + store.snapshot.training.selectedTricks.count
            + store.snapshot.reminders.count
            + (hasWeight ? 1 : 0)
        return !hasNutrition && activityCount <= 3
    }

    private var onboardingStep: OnboardingStep? {
        if store.snapshot.nutrition.plan == nil { return .food }
        let hasHealth = !store.snapshot.health.vaccines.isEmpty
            || !store.snapshot.health.visits.isEmpty
            || !store.snapshot.health.medications.isEmpty
        if !hasHealth { return .health }
        if store.snapshot.reminders.isEmpty { return .reminders }
        return nil
    }

    private func greeting(for date: Date) -> String {
        let base: String
        switch Calendar.current.component(.hour, from: date) {
        case 6..<12: base = String(localized: "Buenos días")
        case 12..<20: base = String(localized: "Buenas tardes")
        default: base = String(localized: "Buenas noches")
        }
        let name = appleDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? base : "\(base), \(name)"
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
        if isInitialProfile { return String(localized: "Buen comienzo") }
        if score >= 84 { return String(localized: "Todo al día") }
        return String(localized: "Buen comienzo")
    }

    private func scoreDetail(for score: Int) -> String {
        if isInitialProfile { return String(localized: "Añade alimentación, salud y recordatorios para mejorarla.") }
        if score >= 84 { return String(localized: "Resume las áreas de cuidado registradas para") + " " + petName + "." }
        return String(localized: "Faltan algunos datos para calcular una puntuación más precisa.")
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(AppTheme.greenSoft.opacity(0.82)).frame(width: 102, height: 102).offset(x: -5, y: 4)
            Circle().fill(AppTheme.orangeSoft.opacity(0.9)).frame(width: 34, height: 34).offset(x: 38, y: -30)
            if store.profilePhotoURL() != nil {
                PetAvatarView(size: 102, photoURL: store.profilePhotoURL())
                    .shadow(color: AppTheme.shadow.opacity(0.14), radius: 10, y: 5)
            } else {
                DogPoseIllustration(pose: .sitting).frame(width: 106, height: 92)
            }
        }.frame(width: 112, height: 106).accessibilityHidden(true)
    }

    @ViewBuilder
    private var heroIdentityBadges: some View {
        HStack(spacing: AppTheme.Space.md) {
            heroBreedBadge
            heroAgeBadge
        }
    }

    @ViewBuilder
    private var heroBreedBadge: some View {
        if !store.snapshot.pet.breed.isEmpty {
            heroBadge(symbol: "pawprint.fill", title: store.snapshot.pet.breed, tint: AppTheme.training)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }

    private var heroAgeBadge: some View {
        heroBadge(symbol: "calendar", title: compactAgeDescription, tint: AppTheme.blue)
            .layoutPriority(1)
    }

    @ViewBuilder
    private var heroWeightBadge: some View {
        if let weight = store.currentWeight {
            heroBadge(symbol: "scalemass", title: AppFormat.weight(weight, unit: store.snapshot.preferences.weightUnit), tint: AppTheme.green)
        }
    }

    private func heroBadge(symbol: String, title: String, tint: Color) -> some View {
        Label(title, systemImage: symbol)
            .font(.caption.weight(.medium))
            .foregroundStyle(tint)
            .lineLimit(1)
            .fixedSize(horizontal: symbol == "calendar", vertical: false)
            .minimumScaleFactor(symbol == "calendar" ? 0.9 : 0.82)
            .padding(.horizontal, AppTheme.Space.sm)
            .padding(.vertical, AppTheme.Space.xs)
            .background(AppTheme.highlight.opacity(0.34), in: Capsule())
    }
    private var compactAgeDescription: String {
        store.snapshot.pet.ageDescription().replacingOccurrences(of: " y ", with: " · ")
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

    private func openSetup(_ step: OnboardingStep) {
        switch step {
        case .food: sheet = .food
        case .health: navigation.selection = .health
        case .reminders: sheet = .reminders
        }
    }
}

#Preview { NavigationStack { HomeView() }.environment(PetPlanifyStore.preview()).environment(AppNavigation()) }
