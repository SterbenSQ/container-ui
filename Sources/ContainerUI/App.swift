import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure app appears in Dock and behaves as a regular application
        NSApp.setActivationPolicy(.regular)

        // Set Dock icon from bundled resource
        if let iconPath = Bundle.module.path(forResource: "Container-ui", ofType: "png"),
           let icon = NSImage(contentsOfFile: iconPath) {
            NSApp.applicationIconImage = icon
        }

        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct ContainerUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
