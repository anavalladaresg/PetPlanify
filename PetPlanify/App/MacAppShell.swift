import SwiftUI

struct MacAppShell: View {
    @State private var selection: AppSection? = .home

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(AppSection.allCases, selection: $selection) { section in
                    Label(section.title, systemImage: section.icon)
                        .tag(section)
                        .accessibilityIdentifier("sidebar.\(section.rawValue)")
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)

                NeoSidebarProfile()
                    .padding(12)
            }
            .background(AppTheme.sidebar)
            .navigationTitle("Neo")
            .navigationSplitViewColumnWidth(min: 210, ideal: 236, max: 270)
        } detail: {
            FeatureDestinationView(section: selection ?? .home)
                .id(selection)
        }
        .navigationSplitViewStyle(.balanced)
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
                Text("Teckel · 3 años")
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
        .accessibilityLabel("Neo, teckel, 3 años")
        .accessibilityIdentifier("profile.neo")
    }
}

