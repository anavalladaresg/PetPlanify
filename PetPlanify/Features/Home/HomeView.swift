import SwiftUI

struct HomeView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(AppNavigation.self) private var navigation
    @State private var sheet: HomeSheet?
    private enum HomeSheet: String, Identifiable {
        case weight, visit, observation, trick, reminders, profile, food
        var id: Self { self }
    }
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            CarePage {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 20) { avatar; profileSummary }
                    VStack(alignment: .leading, spacing: 16) { avatar; profileSummary }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                CareSection(title: "Próximamente") {
                    let upcoming = ReminderEngine.upcoming(store.snapshot.reminders, now: timeline.date)
                    if upcoming.isEmpty {
                        EmptyCareState(title: "Por ahora, todo en orden", symbol: "calendar", message: "Aquí verás los próximos cuidados que hayas añadido.")
                    } else {
                        ForEach(Array(upcoming.prefix(3))) { item in
                            Button { navigation.selection = AppSection(context: item.relatedFeature) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar").foregroundStyle(AppTheme.green).accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.title).font(.headline).foregroundStyle(AppTheme.ink)
                                        Text(AppFormat.dateTime(item.date)).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(AppTheme.secondaryInk).accessibilityHidden(true)
                                }.padding(.vertical, 5).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                        if upcoming.count > 3 { Button("Ver todos") { sheet = .reminders } }
                    }
                }
                if !setupTasks.isEmpty {
                    CareSection(title: "Completar PetPlanify") {
                        ForEach(setupTasks, id: \.id) { item in
                            HStack {
                                Button(item.title) { openSetup(item.id) }
                                Spacer()
                                Button("Omitir esta sugerencia", systemImage: "xmark") {
                                    Task { _ = await store.update { $0.onboarding.dismissedSetupTasks.insert(item.id) } }
                                }.labelStyle(.iconOnly).buttonStyle(.borderless).frame(minWidth: 44, minHeight: 44).foregroundStyle(AppTheme.secondaryInk)
                            }
                        }
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
            }
        }
        .accessibilityIdentifier("home.screen")
    }
    private var avatar: some View { PetAvatarView(size: 86, photoURL: store.profilePhotoURL()) }
    private var profileSummary: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(store.snapshot.pet.name).font(.largeTitle.weight(.semibold)).fontDesign(.serif)
            Text([store.snapshot.pet.breed, store.snapshot.pet.ageDescription()].filter { !$0.isEmpty }.joined(separator: " · "))
                .foregroundStyle(AppTheme.secondaryInk)
            if let weight = store.currentWeight { Text(AppFormat.weight(weight, unit: store.snapshot.preferences.weightUnit)).font(.headline) }
        }.accessibilityElement(children: .combine)
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
