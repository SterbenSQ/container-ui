import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Suppress Apple framework debug noise (TSM/IMK) on stderr
        // Harmless messages from text input system when running outside .app bundle
        freopen("/dev/null", "w", stderr)

        // Ensure app appears in Dock and behaves as a regular application
        NSApp.setActivationPolicy(.regular)

        // Set Dock icon from bundled resource, resized to standard 256x256
        if let iconPath = Bundle.module.path(forResource: "Container-ui", ofType: "png"),
           let rawIcon = NSImage(contentsOfFile: iconPath) {
            let iconSize = NSSize(width: 256, height: 256)
            let resized = NSImage(size: iconSize)
            resized.lockFocus()
            rawIcon.draw(in: NSRect(origin: .zero, size: iconSize),
                         from: NSRect(origin: .zero, size: rawIcon.size),
                         operation: .copy, fraction: 1.0)
            resized.unlockFocus()
            NSApp.applicationIconImage = resized
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
