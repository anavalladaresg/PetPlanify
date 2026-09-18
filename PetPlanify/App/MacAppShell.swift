import SwiftUI

struct MacAppShell: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(AppNavigation.self) private var navigation
    var body: some View {
        @Bindable var navigation = navigation
        NavigationSplitView {
            List(selection: Binding<AppSection?>(
                get: { navigation.selection },
                set: { if let value = $0 { navigation.selection = value } }
            )) {
                Section {
                    PetSwitcher()
                }
                ForEach(AppSection.allCases) { section in
                    Label(section.title, systemImage: section.icon)
                        .font(.body.weight(navigation.selection == section ? .semibold : .regular))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(navigation.selection == section ? AppTheme.green : AppTheme.ink)
                        .padding(.vertical, AppTheme.Space.sm)
                        .padding(.horizontal, AppTheme.Space.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(navigation.selection == section ? AppTheme.greenSoft.opacity(0.82) : .clear, in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
                        .shadow(color: navigation.selection == section ? AppTheme.highlight.opacity(0.55) : .clear, radius: 4, x: -2, y: -2)
                        .shadow(color: navigation.selection == section ? AppTheme.shadow.opacity(0.16) : .clear, radius: 4, x: 2, y: 2)
                        .tag(section)
                        .accessibilityIdentifier("sidebar.\(section.rawValue)")
                        .accessibilityAddTraits(navigation.selection == section ? .isSelected : [])
                        .listRowInsets(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
                        .listRowBackground(AppTheme.sidebar)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(AppTheme.sidebar)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    PetAvatarView(size: 40, photoURL: store.profilePhotoURL())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.snapshot.pet.name).font(.headline)
                        Text(store.snapshot.pet.breed).font(.caption).foregroundStyle(AppTheme.secondaryInk)
                    }
                    Spacer(minLength: 0)
                }.padding(AppTheme.Space.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: AppTheme.compactRadius).fill(AppTheme.surface.opacity(0.40)).padding(8))
                    .shadow(color: AppTheme.highlight.opacity(0.45), radius: 7, x: -3, y: -3)
                    .shadow(color: AppTheme.shadow.opacity(0.13), radius: 7, x: 3, y: 3)
                    .overlay(alignment: .top) { Divider().opacity(0.5) }
                    .accessibilityElement(children: .combine)
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
