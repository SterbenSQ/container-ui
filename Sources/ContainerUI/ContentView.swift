import SwiftUI

struct ContentView: View {
    @EnvironmentObject var l10n: LocalizationManager
    @State private var selectedTab: Tabs = .dashboard

    enum Tabs: String, CaseIterable, Identifiable {
        case dashboard, containers, images, build

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard: return "gauge.with.dots.needle.33percent"
            case .containers: return "square.stack.3d.down.right"
            case .images: return "photo.stack"
            case .build: return "hammer"
            }
        }

        func localizedName(using l10n: LocalizationManager) -> String {
            switch self {
            case .dashboard: return l10n["tab.dashboard"]
            case .containers: return l10n["tab.containers"]
            case .images: return l10n["tab.images"]
            case .build: return l10n["tab.build"]
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(Tabs.dashboard.localizedName(using: l10n), systemImage: Tabs.dashboard.icon)
                }
                .tag(Tabs.dashboard)

            ContainerListView()
                .tabItem {
                    Label(Tabs.containers.localizedName(using: l10n), systemImage: Tabs.containers.icon)
                }
                .tag(Tabs.containers)

            ImageListView()
                .tabItem {
                    Label(Tabs.images.localizedName(using: l10n), systemImage: Tabs.images.icon)
                }
                .tag(Tabs.images)

            ImageBuildView()
                .tabItem {
                    Label(Tabs.build.localizedName(using: l10n), systemImage: Tabs.build.icon)
                }
                .tag(Tabs.build)
        }
        .padding()
    }
}
