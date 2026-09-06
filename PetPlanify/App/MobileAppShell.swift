import SwiftUI

struct MobileAppShell: View {
    @Environment(AppNavigation.self) private var navigation
    var body: some View {
        @Bindable var navigation = navigation
        TabView(selection: $navigation.selection) {
            ForEach(AppSection.allCases) { section in
                NavigationStack {
                    FeatureDestinationView(section: section)
                        .navigationTitle(section.title)
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.large)
                        #endif
                        .toolbar { ToolbarItem(placement: .primaryAction) { AppReminderButton() } }
                }
                .tabItem { Label(section.title, systemImage: section.icon) }
                .tag(section)
                .accessibilityIdentifier("tab.\(section.rawValue)")
            }
        }.tint(AppTheme.green).accessibilityIdentifier("navigation.iphone")
    }
}
