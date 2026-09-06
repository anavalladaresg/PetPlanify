import SwiftUI

struct HomeView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(AppNavigation.self) private var navigation
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
                profileHero
                CareSection(title: "Próximamente", style: .plain) {
                    let upcoming = ReminderEngine.upcoming(store.snapshot.reminders, now: timeline.date)
                    if upcoming.isEmpty {
                        EmptyCareState(title: "Por ahora, todo en orden", symbol: "calendar", message: "Aquí verás los próximos cuidados que hayas añadido.")
                            .padding(AppTheme.Space.lg).appSurface()
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(upcoming.prefix(3))) { item in
                                upcomingRow(item)
                                if item.id != upcoming.prefix(3).last?.id {
                                    Divider().padding(.leading, 56)
                                }
                            }
                        }
                        if upcoming.count > 3 { Button("Ver todos") { sheet = .reminders } }
                    }
                }
                if !setupTasks.isEmpty {
                    DisclosureGroup(isExpanded: $setupExpanded) {
                        VStack(spacing: AppTheme.Space.sm) {
                            ForEach(setupTasks, id: \.id) { item in
                                HStack {
                                    Button(item.title) { openSetup(item.id) }.frame(minHeight: 44)
                                    Spacer()
                                    Button("Omitir esta sugerencia", systemImage: "xmark") {
                                        Task { _ = await store.update { $0.onboarding.dismissedSetupTasks.insert(item.id) } }
                                    }.labelStyle(.iconOnly).buttonStyle(.borderless).frame(minWidth: 44, minHeight: 44).foregroundStyle(AppTheme.secondaryInk)
                                }
                            }
                        }.padding(.top, AppTheme.Space.sm)
                    } label: {
                        Label("Completar PetPlanify", systemImage: "sparkle").font(.subheadline.weight(.medium))
                    }
                    .padding(AppTheme.Space.lg).background(AppTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: AppTheme.compactRadius))
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
    private var profileHero: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppTheme.Space.xl) { avatar; profileSummary }
            VStack(alignment: .leading, spacing: AppTheme.Space.md) { avatar; profileSummary }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Space.xl)
        .background(AppTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: AppTheme.heroRadius))
        .overlay(alignment: .topTrailing) {
            Button { sheet = .profile } label: {
                Image(systemName: "pencil").font(.subheadline).frame(width: 44, height: 44).contentShape(Rectangle())
            }.buttonStyle(.plain).foregroundStyle(AppTheme.green).accessibilityLabel("Editar perfil")
        }
    }
    private var avatar: some View {
        ZStack {
            Circle().fill(AppTheme.greenSoft.opacity(0.7)).frame(width: 96, height: 96).offset(x: -5, y: 4)
            if store.profilePhotoURL() != nil {
                PetAvatarView(size: 92, photoURL: store.profilePhotoURL())
                    .shadow(color: AppTheme.shadow.opacity(0.12), radius: 8, y: 4)
            } else {
                DogPoseIllustration(pose: .sitting).frame(width: 116, height: 100)
            }
        }.frame(width: 116, height: 104).accessibilityHidden(true)
    }
    private var profileSummary: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
            Text(store.snapshot.pet.name).font(.largeTitle.weight(.medium)).fontDesign(.serif)
            Text([store.snapshot.pet.breed, store.snapshot.pet.ageDescription()].filter { !$0.isEmpty }.joined(separator: " · "))
                .font(.subheadline).foregroundStyle(AppTheme.secondaryInk).fixedSize(horizontal: false, vertical: true)
            if let weight = store.currentWeight {
                Text(AppFormat.weight(weight, unit: store.snapshot.preferences.weightUnit))
                    .font(.subheadline.weight(.medium)).monospacedDigit().padding(.top, AppTheme.Space.xs)
            }
        }.padding(.trailing, AppTheme.Space.md).accessibilityElement(children: .combine)
    }
    private func upcomingRow(_ item: CareReminder) -> some View {
        Button {
            if item.relatedFeature == .general { sheet = .reminders }
            else { navigation.selection = AppSection(context: item.relatedFeature) }
        } label: {
            HStack(spacing: AppTheme.Space.lg) {
                CareSymbol(systemName: item.relatedFeature == .general ? "calendar" : AppSection(context: item.relatedFeature).icon,
                           accent: item.relatedFeature == .health ? AppTheme.orange : AppTheme.green, size: 40)
                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text(item.title).font(.body.weight(.medium)).foregroundStyle(AppTheme.ink)
                    Text(AppFormat.dateTime(item.date)).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                    Text(item.relatedFeature.title).font(.caption).foregroundStyle(AppTheme.green)
                }.fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk).accessibilityHidden(true)
            }.padding(.vertical, AppTheme.Space.md).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityElement(children: .combine)
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
