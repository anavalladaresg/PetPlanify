import SwiftUI

struct MobileAppShell: View {
    @State private var selectedTab: AppSection = .home
    @State private var reminders = DailyCarePreviewData.reminders

    var body: some View {
        TabView(selection: $selectedTab) {
            mobileTab(.home)
            mobileTab(.nutrition)
            mobileTab(.health)
            mobileTab(.training)

            NavigationStack {
                MoreView()
                    .toolbar { reminderToolbar }
            }
            .tabItem {
                Label("Más", systemImage: "ellipsis")
            }
            .tag(AppSection.settings)
            .accessibilityIdentifier("tab.more")
        }
        .tint(AppTheme.green)
        .accessibilityIdentifier("navigation.iphone")
    }

    private func mobileTab(_ section: AppSection) -> some View {
        NavigationStack {
            FeatureDestinationView(section: section)
                .navigationTitle(section.title)
                .toolbar { reminderToolbar }
        }
        .tabItem {
            Label(section.title, systemImage: section.icon)
        }
        .tag(section)
        .accessibilityIdentifier("tab.\(section.rawValue)")
    }

    @ToolbarContentBuilder
    private var reminderToolbar: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            AppReminderButton(reminders: $reminders) { section in
                selectedTab = [.home, .nutrition, .health, .training].contains(section)
                    ? section
                    : .settings
            }
        }
    }
}

private struct MoreView: View {
    private let sections: [AppSection] = [
        .evolution,
        .settings
    ]

    var body: some View {
        List(sections) { section in
            NavigationLink {
                FeatureDestinationView(section: section)
                    .navigationTitle(section.title)
            } label: {
                Label(section.title, systemImage: section.icon)
                    .foregroundStyle(AppTheme.ink)
                    .padding(.vertical, 7)
            }
            .accessibilityIdentifier("more.\(section.rawValue)")
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.canvas)
        .navigationTitle("Más")
    }
}
