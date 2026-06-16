import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var l10n: LocalizationManager
    @EnvironmentObject private var vm: DashboardViewModel
    @State private var autoRefreshTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text(l10n["dashboard.title"])
                    .font(.largeTitle)
                    .bold()

                // System Status Card
                systemStatusCard

                // Overview Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    overviewCard(
                        title: l10n["dashboard.containers"],
                        value: "\(vm.containerCount)",
                        icon: "square.stack.3d.down.right",
                        color: .blue
                    )
                    overviewCard(
                        title: l10n["dashboard.images"],
                        value: "\(vm.imageCount)",
                        icon: "photo.stack",
                        color: .purple
                    )
                    overviewCard(
                        title: l10n["dashboard.system"],
                        value: vm.isRunning ? l10n["dashboard.running"] : l10n["dashboard.stopped"],
                        icon: vm.isRunning ? "checkmark.circle.fill" : "xmark.circle.fill",
                        color: vm.isRunning ? .green : .red
                    )
                }

                // Disk Usage
                if let usage = vm.diskUsage {
                    diskUsageSection(usage: usage)
                }

                // Version Info
                if !vm.versions.isEmpty {
                    versionSection
                }
            }
            .padding()
        }
        .task {
            await vm.refresh()
            // Auto-refresh every 5 seconds so UI stays in sync with daemon
            autoRefreshTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    guard !Task.isCancelled else { break }
                    await vm.refresh()
                }
            }
        }
        .onDisappear {
            autoRefreshTask?.cancel()
        }
        .toolbar {
            ToolbarItemGroup {
                // Language switcher
                Picker("", selection: $l10n.currentLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.nativeDisplayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)

                Button {
                    Task { await vm.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help(l10n["dashboard.refresh"])

                if vm.isRunning {
                    Button {
                        Task { await vm.stopSystem() }
                    } label: {
                        Image(systemName: "stop.circle")
                    }
                    .help(l10n["dashboard.stop"])
                } else {
                    Button {
                        Task { await vm.startSystem() }
                    } label: {
                        Image(systemName: "play.circle")
                    }
                    .help(l10n["dashboard.start"])
                }
            }
        }
        .overlay {
            if vm.isLoading {
                ProgressView(l10n["dashboard.loading"])
            }
        }
        .overlay(alignment: .bottom) {
            if let error = vm.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding()
                .transition(.move(edge: .bottom))
                .onTapGesture { vm.errorMessage = nil }
            }
        }
    }

    // MARK: - System Status Card

    private var systemStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: vm.isRunning ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(vm.isRunning ? .green : .orange)
                Text(vm.isRunning ? l10n["dashboard.system.running"] : l10n["dashboard.system.not.running"])
                    .font(.headline)
                Spacer()
            }

            if let status = vm.systemStatus {
                Group {
                    if let version = status.apiServerVersion {
                        LabeledContent(l10n["dashboard.version"], value: version)
                    }
                    if let build = status.apiServerBuild {
                        LabeledContent(l10n["dashboard.build"], value: build)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Overview Card

    private func overviewCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(value)
                .font(.title)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Disk Usage

    private func diskUsageSection(usage: DiskUsageModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(l10n["dashboard.disk.usage"])
                    .font(.headline)
                Spacer()

                // Reclaim button
                if vm.totalReclaimable > 0 {
                    if vm.isPruning {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text(l10n["dashboard.pruning"])
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button {
                            Task { await vm.pruneSystem() }
                        } label: {
                            Label(l10n.format("dashboard.reclaim.button", ["size": vm.totalReclaimableFormatted]),
                                  systemImage: "arrow.3.trianglepath")
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                }

                if let result = vm.pruneResult {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(l10n.format("dashboard.reclaimed", ["size": result]))
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            HStack(spacing: 16) {
                diskUsageCard(title: l10n["dashboard.images"], usage: usage.images, color: .purple)
                diskUsageCard(title: l10n["dashboard.containers"], usage: usage.containers, color: .blue)
                diskUsageCard(title: l10n["dashboard.volumes"], usage: usage.volumes, color: .green)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func diskUsageCard(title: String, usage: ResourceUsageModel, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .bold()
                .foregroundColor(color)
            Text(l10n.format("dashboard.active_total", ["active": "\(usage.active)", "total": "\(usage.total)"]))
                .font(.caption)
            Text(usage.sizeFormatted)
                .font(.caption)
                .foregroundColor(.secondary)
            if usage.reclaimable > 0 {
                Text(l10n.format("dashboard.reclaimable", ["size": usage.reclaimableFormatted]))
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Version

    private var versionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(l10n["dashboard.versions"])
                .font(.headline)

            ForEach(vm.versions, id: \.appName) { version in
                HStack {
                    Text(version.appName ?? "Unknown")
                        .font(.caption)
                        .bold()
                    Text(version.version)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let build = version.buildType {
                        Text("(\(build))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
