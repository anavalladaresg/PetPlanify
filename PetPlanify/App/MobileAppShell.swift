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
            mobileTab(.settings)
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
                selectedTab = section
            }
        }
    }
}
