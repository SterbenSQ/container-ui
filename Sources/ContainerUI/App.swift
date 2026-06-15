import SwiftUI

@main
struct ContainerUIApp: App {
    @StateObject private var l10n = LocalizationManager.shared
    @StateObject private var dashboardVM = DashboardViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(l10n)
                .environmentObject(dashboardVM)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .commands {
            // Language switcher in app menu
            CommandGroup(after: .appSettings) {
                Divider()
                Menu(l10n.currentLanguage.displayName) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button(lang.nativeDisplayName) {
                            l10n.currentLanguage = lang
                        }
                        .keyboardShortcut(lang == .english ? .init("e", modifiers: .command) : .init("c", modifiers: .command))
                    }
                }
            }
        }
    }
}
