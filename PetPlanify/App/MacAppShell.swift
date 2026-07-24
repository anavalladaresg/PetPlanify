import SwiftUI

struct MacAppShell: View {
    @State private var selection: AppSection? = .home
    @State private var reminders = DailyCarePreviewData.reminders

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List {
                    ForEach(AppSection.allCases) { section in
                        Button {
                            selection = section
                        } label: {
                            Label(section.title, systemImage: section.icon)
                                .foregroundStyle(selection == section ? AppTheme.green : AppTheme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 7)
                                .padding(.horizontal, 9)
                                .background(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(selection == section ? AppTheme.greenSoft : .clear)
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selection == section ? .isSelected : [])
                        .accessibilityIdentifier("sidebar.\(section.rawValue)")
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)

                NeoSidebarProfile()
                    .padding(12)
            }
            .background(AppTheme.sidebar)
            .navigationTitle("Neo")
            .navigationSplitViewColumnWidth(min: 186, ideal: 208, max: 232)
        } detail: {
            FeatureDestinationView(section: selection ?? .home)
                .id(selection)
                .toolbar {
                    ToolbarItem {
                        AppReminderButton(reminders: $reminders) {
                            selection = $0
                        }
                    }
                }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(AppTheme.green)
        .frame(minWidth: 900, minHeight: 650)
        .accessibilityIdentifier("navigation.mac")
    }
}

private struct NeoSidebarProfile: View {
    var body: some View {
        HStack(spacing: 11) {
            PetAvatarView(size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text("Neo")
                    .font(.subheadline.weight(.semibold))
                Text("Teckel · 2 años")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.surface.opacity(0.72))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Neo, teckel, 2 años")
        .accessibilityIdentifier("profile.neo")
    }
}
