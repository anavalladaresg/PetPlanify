import SwiftUI

struct MacAppShell: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(AppNavigation.self) private var navigation
    var body: some View {
        NavigationSplitView {
            List(selection: Binding<AppSection?>(get: { navigation.selection }, set: { if let value = $0 { navigation.selection = value } })) {
                ForEach(AppSection.allCases) { section in
                    Label(section.title, systemImage: section.icon)
                        .padding(.vertical, 5)
                        .tag(section)
                        .accessibilityIdentifier("sidebar.\(section.rawValue)")
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    PetAvatarView(size: 40, photoURL: store.profilePhotoURL())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.snapshot.pet.name).font(.headline)
                        Text(store.snapshot.pet.breed).font(.caption).foregroundStyle(AppTheme.secondaryInk)
                    }
                    Spacer(minLength: 0)
                }.padding(16).accessibilityElement(children: .combine)
            }
            .navigationTitle("PetPlanify")
            .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 250)
        } detail: {
            NavigationStack {
                FeatureDestinationView(section: navigation.selection)
                    .navigationTitle(navigation.selection.title)
                    .toolbar { ToolbarItem { AppReminderButton() } }
            }.id(navigation.selection)
        }
        .navigationSplitViewStyle(.balanced)
        .tint(AppTheme.green)
        .frame(minWidth: 660, minHeight: 520)
        .accessibilityIdentifier("navigation.mac")
    }
}
