import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var l10n: LocalizationManager
    @EnvironmentObject private var vm: DashboardViewModel
    @State private var autoRefreshTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DT.sectionSpacing) {
                DT.pageTitle(l10n["dashboard.title"])

                systemStatusCard

                // Overview stat cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: DT.cardSpacing) {
                    statCard(
                        title: l10n["dashboard.containers"],
                        value: "\(vm.containerCount)",
                        icon: "square.stack.3d.down.right",
                        gradient: DT.Gradient.blue
                    )
                    statCard(
                        title: l10n["dashboard.images"],
                        value: "\(vm.imageCount)",
                        icon: "photo.stack",
                        gradient: DT.Gradient.purple
                    )
                    statCard(
                        title: l10n["dashboard.system"],
                        value: vm.isRunning ? l10n["dashboard.running"] : l10n["dashboard.stopped"],
                        icon: vm.isRunning ? "checkmark.circle.fill" : "xmark.circle.fill",
                        gradient: vm.isRunning ? DT.Gradient.green : DT.Gradient.red
                    )
                }

                if let usage = vm.diskUsage {
                    diskUsageSection(usage: usage)
                }

                if !vm.versions.isEmpty {
                    versionSection
                }
            }
            .padding()
        }
        .task {
            await vm.refresh()
            autoRefreshTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    guard !Task.isCancelled else { break }
                    await vm.refresh()
                }
            }
        }
        .onDisappear { autoRefreshTask?.cancel() }
        .toolbar {
            ToolbarItemGroup {
                Picker("", selection: $l10n.currentLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.nativeDisplayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)

                Button { Task { await vm.refresh() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help(l10n["dashboard.refresh"])

                if vm.isRunning {
                    Button { Task { await vm.stopSystem() } } label: {
                        Image(systemName: "stop.circle")
                    }
                    .help(l10n["dashboard.stop"])
                } else {
                    Button { Task { await vm.startSystem() } } label: {
                        Image(systemName: "play.circle")
                    }
                    .help(l10n["dashboard.start"])
                }
            }
        }
        .overlay { if vm.isLoading { ProgressView(l10n["dashboard.loading"]) } }
        .alert(l10n["common.error"], isPresented: .init(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button(l10n["common.ok"], role: .cancel) {}
        } message: { Text(vm.errorMessage ?? "") }
    }

    // MARK: - System Status Card

    private var systemStatusCard: some View {
        HStack(spacing: DT.cardSpacing) {
            GradientIcon(
                systemName: vm.isRunning ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                gradient: vm.isRunning ? DT.Gradient.green : DT.Gradient.orange,
                size: 48
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(vm.isRunning ? l10n["dashboard.system.running"] : l10n["dashboard.system.not.running"])
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                if let status = vm.systemStatus {
                    HStack(spacing: 12) {
                        if let version = status.apiServerVersion {
                            Text("\(l10n["dashboard.version"]): \(version)")
                        }
                        if let build = status.apiServerBuild {
                            Text("\(l10n["dashboard.build"]): \(build)")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: DT.cardRadius))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    // MARK: - Stat Card

    private func statCard(title: String, value: String, icon: String, gradient: LinearGradient) -> some View {
        VStack(spacing: DT.innerSpacing) {
            GradientIcon(systemName: icon, gradient: gradient, size: 44)
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: DT.cardRadius))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    // MARK: - Disk Usage

    private func diskUsageSection(usage: DiskUsageModel) -> some View {
        VStack(alignment: .leading, spacing: DT.innerSpacing) {
            HStack {
                Text(l10n["dashboard.disk.usage"])
                    .font(.headline)
                Spacer()

                if vm.totalReclaimable > 0 {
                    if vm.isPruning {
                        HStack(spacing: 4) {
                            ProgressView().scaleEffect(0.7)
                            Text(l10n["dashboard.pruning"])
                                .font(.caption).foregroundColor(.secondary)
                        }
                    } else {
                        Button { Task { await vm.pruneSystem() } } label: {
                            Label(l10n.format("dashboard.reclaim.button", ["size": vm.totalReclaimableFormatted]),
                                  systemImage: "arrow.3.trianglepath")
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                }

                if let result = vm.pruneResult {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        Text(l10n.format("dashboard.reclaimed", ["size": result]))
                            .font(.caption).foregroundColor(.green)
                    }
                }
            }

            VStack(spacing: 10) {
                diskUsageBar(title: l10n["dashboard.images"], usage: usage.images, gradient: DT.Gradient.purple)
                diskUsageBar(title: l10n["dashboard.containers"], usage: usage.containers, gradient: DT.Gradient.blue)
                diskUsageBar(title: l10n["dashboard.volumes"], usage: usage.volumes, gradient: DT.Gradient.green)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: DT.cardRadius))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private func diskUsageBar(title: String, usage: ResourceUsageModel, gradient: LinearGradient) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline).bold()
                Spacer()
                Text(usage.sizeFormatted)
                    .font(.caption).foregroundColor(.secondary).monospaced()
                if usage.reclaimable > 0 {
                    Text("·")
                    Text(l10n.format("dashboard.reclaimable", ["size": usage.reclaimableFormatted]))
                        .font(.caption).foregroundColor(.orange)
                }
            }

            GeometryReader { geo in
                let total = max(usage.sizeInBytes, 1)
                let reclaimRatio = min(CGFloat(usage.reclaimable) / CGFloat(total), 1.0)
                let usedRatio = 1.0 - reclaimRatio

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(nsColor: .separatorColor))
                    Capsule()
                        .fill(gradient)
                        .frame(width: geo.size.width * usedRatio)
                    Capsule()
                        .fill(DT.Gradient.orange)
                        .frame(width: geo.size.width * reclaimRatio)
                        .opacity(0.55)
                }
            }
            .frame(height: 8)

            Text(l10n.format("dashboard.active_total", ["active": "\(usage.active)", "total": "\(usage.total)"]))
                .font(.caption2).foregroundColor(.secondary)
        }
    }

    // MARK: - Version

    private var versionSection: some View {
        VStack(alignment: .leading, spacing: DT.innerSpacing) {
            Text(l10n["dashboard.versions"]).font(.headline)
            ForEach(vm.versions, id: \.appName) { version in
                HStack {
                    Text(version.appName ?? "Unknown")
                        .font(.caption).bold()
                    Text(version.version)
                        .font(.caption).foregroundColor(.secondary)
                    if let build = version.buildType {
                        Text("(\(build))")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: DT.cardRadius))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}
