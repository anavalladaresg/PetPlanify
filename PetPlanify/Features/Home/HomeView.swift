import SwiftUI

struct HomeView: View {
    enum QuickAction: String, Identifiable {
        case weight, appointment, observation, trick

        var id: String { rawValue }

        var title: String {
            switch self {
            case .weight: "Registrar peso"
            case .appointment: "Añadir cita veterinaria"
            case .observation: "Añadir observación"
            case .trick: "Añadir truco"
            }
        }

        var symbol: String {
            switch self {
            case .weight: "scalemass"
            case .appointment: "calendar.badge.plus"
            case .observation: "square.and.pencil"
            case .trick: "plus.circle"
            }
        }
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var presentedAction: QuickAction?
    @State private var showsAllUpcoming = false

    let pet: PetProfile

    private var isCompact: Bool { horizontalSizeClass == .compact }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isCompact ? 14 : 22) {
                header
                identity
                upcoming
            }
            .frame(maxWidth: 960, alignment: .leading)
            .padding(isCompact ? 16 : 28)
            .padding(.bottom, isCompact ? 12 : 0)
        }
        .appCanvas()
        .accessibilityIdentifier("home.screen")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                quickActionMenu
            }
            #else
            ToolbarItem(placement: .automatic) {
                quickActionMenu
            }
            #endif
        }
        .sheet(item: $presentedAction) { action in
            HomeFutureActionSheet(action: action) {
                presentedAction = nil
            }
        }
        .sheet(isPresented: $showsAllUpcoming) {
            HomeUpcomingSheet(reminders: DailyCarePreviewData.reminders)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !isCompact {
                Text("Inicio")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            Text("¿Qué tengo que recordar sobre Neo?")
                .font(isCompact ? .headline : .title3)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home.greeting")
    }

    private var identity: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 14) {
                identityBlock
                Spacer(minLength: 10)
                weightBlock
            }
            VStack(alignment: .leading, spacing: 12) {
                identityBlock
                weightBlock
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isCompact ? 14 : 16)
        .appSurface(cornerRadius: isCompact ? 15 : 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pet.name), \(pet.breed), \(pet.age), peso actual \(pet.currentWeight)")
        .accessibilityIdentifier("home.petSummary")
    }

    private var identityBlock: some View {
        HStack(spacing: 12) {
            PetAvatarView(size: isCompact ? 58 : 62)
            VStack(alignment: .leading, spacing: 3) {
                Text(pet.name)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                Text("\(pet.breed) · \(pet.age)")
                    .foregroundStyle(AppTheme.secondaryInk)
            }
        }
    }

    private var weightBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Peso actual")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
            Text(pet.currentWeight)
                .font(.title3.weight(.semibold))
        }
    }

    private var upcoming: some View {
        let allReminders = DailyCarePreviewData.reminders
        let visibleReminders = isCompact ? Array(allReminders.prefix(3)) : allReminders
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Próximamente")
                    .font(.system(.title2, design: .serif, weight: .semibold))
                Spacer()
                if isCompact && allReminders.count > visibleReminders.count {
                    Button("Ver todos") {
                        showsAllUpcoming = true
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.green)
                }
            }
            VStack(spacing: 0) {
                ForEach(visibleReminders) { reminder in
                    upcomingRow(reminder)
                    if reminder.id != visibleReminders.last?.id {
                        Divider().overlay(AppTheme.border)
                    }
                }
            }
            .padding(.horizontal, 16)
            .appSurface(cornerRadius: 16)
        }
        .accessibilityIdentifier("home.upcoming")
    }

    private func upcomingRow(_ reminder: CareReminder) -> some View {
        HStack(spacing: 12) {
            Image(systemName: reminderIcon(reminder))
                .foregroundStyle(AppTheme.green)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title).font(.subheadline.weight(.semibold))
                Text(reminder.date.formatted(
                    Date.FormatStyle(date: .long, time: .shortened)
                        .locale(Locale(identifier: "es_ES"))
                ))
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                Text(reminder.notes)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
            }
            Spacer()
        }
        .padding(.vertical, isCompact ? 10 : 12)
        .accessibilityElement(children: .combine)
    }

    private func reminderIcon(_ reminder: CareReminder) -> String {
        if reminder.title.contains("Vacuna") { return "syringe" }
        if reminder.title.contains("cita") { return "cross.case" }
        if reminder.title.contains("interna") { return "pills" }
        if reminder.title.contains("externa") { return "drop" }
        if reminder.title.contains("Antiparasitario") { return "pills" }
        return "scalemass"
    }

    private var quickActionMenu: some View {
        Menu {
            ForEach([QuickAction.weight, .appointment, .observation, .trick]) { action in
                Button {
                    presentedAction = action
                } label: {
                    Label(action.title, systemImage: action.symbol)
                }
            }
        } label: {
            Label("Añadir", systemImage: "plus")
        }
        .help("Añadir información sobre Neo")
        .accessibilityIdentifier("app.quickActions")
    }
}

private struct HomeUpcomingSheet: View {
    @Environment(\.dismiss) private var dismiss
    let reminders: [CareReminder]

    var body: some View {
        NavigationStack {
            List(reminders) { reminder in
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.headline)
                    Text(
                        reminder.date.formatted(
                            Date.FormatStyle(date: .long, time: .shortened)
                                .locale(Locale(identifier: "es_ES"))
                        )
                    )
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
                    Text(reminder.notes)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                .padding(.vertical, 5)
                .accessibilityElement(children: .combine)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.canvas)
            .navigationTitle("Próximamente")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

private struct HomeFutureActionSheet: View {
    let action: HomeView.QuickAction
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: action.symbol)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(AppTheme.green)
                .accessibilityHidden(true)
            Text(action.title)
                .font(.system(.title2, design: .serif, weight: .semibold))
            Text("El formulario será funcional cuando definamos el modelo de datos definitivo.")
                .foregroundStyle(AppTheme.secondaryInk)
                .multilineTextAlignment(.center)
            Button("Cerrar", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.green)
        }
        .frame(maxWidth: 400)
        .padding(30)
        .appCanvas()
    }
}

#Preview("Inicio") {
    HomeView(pet: PreviewData.neo)
        .frame(width: 1_000, height: 700)
}
