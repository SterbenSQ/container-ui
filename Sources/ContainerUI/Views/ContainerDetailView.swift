import SwiftUI

struct ContainerDetailView: View {
    @EnvironmentObject var l10n: LocalizationManager
    let containerId: String
    @StateObject private var vm = ContainerDetailViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                if let detail = vm.detail {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(detail.name)
                            .font(.system(.title, design: .rounded))
                            .bold()
                        HStack {
                            Circle()
                                .fill(detail.isRunning ? DT.Gradient.green : DT.Gradient.red)
                                .frame(width: 10, height: 10)
                                .shadow(color: (detail.isRunning ? Color.green : Color.red).opacity(0.5), radius: 4)
                            Text(detail.state.capitalized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(detail.image)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Tab selector
                Picker("", selection: $vm.selectedTab) {
                    ForEach(ContainerDetailViewModel.DetailTab.allCases) { tab in
                        Text(tab.localizedName(using: l10n)).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Tab content
                TabView(selection: $vm.selectedTab) {
                    inspectView
                        .tag(ContainerDetailViewModel.DetailTab.inspect)

                    statsView
                        .tag(ContainerDetailViewModel.DetailTab.stats)

                    logsView
                        .tag(ContainerDetailViewModel.DetailTab.logs)
                }
                .tabViewStyle(.automatic)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(l10n["container.detail.close"]) {
                        dismiss()
                    }
                }
            }
            .frame(minWidth: 600, minHeight: 400)
            .task {
                await vm.loadDetail(id: containerId)
            }
            .onDisappear {
                vm.stopStatsRefresh()
            }
            .onChange(of: vm.selectedTab) { _, newTab in
                if newTab == .stats {
                    vm.startStatsRefresh(id: containerId)
                } else if newTab == .logs {
                    Task { await vm.loadLogs(id: containerId) }
                } else {
                    vm.stopStatsRefresh()
                }
            }
        }
    }

    // MARK: - Inspect Tab

    private var inspectView: some View {
        ScrollView {
            if let detail = vm.detail {
                VStack(alignment: .leading, spacing: 16) {
                    // Configuration
                    GroupBox(l10n["container.detail.config"]) {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledContent(l10n["container.detail.id"], value: detail.configuration.id)
                            LabeledContent(l10n["container.detail.image"], value: detail.image)
                            LabeledContent(l10n["container.detail.runtime"], value: detail.configuration.runtimeHandler ?? "—")
                            if let resources = detail.configuration.resources {
                                LabeledContent(l10n["container.detail.cpus"], value: "\(resources.cpus ?? 4)")
                                LabeledContent(l10n["container.detail.memory"], value: resources.memoryFormatted)
                            }
                            LabeledContent(l10n["container.detail.created"], value: detail.created.formatted(date: .numeric, time: .shortened))
                            if let started = detail.startedDate {
                                LabeledContent(l10n["container.detail.started"], value: started.formatted(date: .numeric, time: .shortened))
                            }
                        }
                        .font(.caption)
                    }

                    // Process Info
                    GroupBox(l10n["container.detail.process"]) {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledContent(l10n["container.detail.executable"], value: detail.configuration.initProcess.executable)
                            let args = detail.configuration.initProcess.arguments ?? []
                            if !args.isEmpty {
                                LabeledContent(l10n["container.detail.arguments"], value: args.joined(separator: " "))
                            }
                        }
                        .font(.caption)
                    }

                    // Ports
                    if let ports = detail.configuration.publishedPorts, !ports.isEmpty {
                        GroupBox(l10n["container.detail.ports"]) {
                            ForEach(ports.indices, id: \.self) { i in
                                let p = ports[i]
                                Text("\(p.hostAddress.map { "\($0):" } ?? "")\(p.hostPort) → \(p.containerPort)/\(p.proto ?? "tcp")")
                                    .font(.caption)
                            }
                        }
                    }

                    // Labels
                    if let labels = detail.configuration.labels, !labels.isEmpty {
                        GroupBox(l10n["container.detail.labels"]) {
                            ForEach(Array(labels.keys).sorted(), id: \.self) { key in
                                LabeledContent(key, value: labels[key] ?? "")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding()
            } else if vm.errorMessage != nil {
                ContentUnavailableView(
                    l10n["container.detail.error"],
                    systemImage: "exclamationmark.triangle",
                    description: Text(vm.errorMessage ?? "")
                )
            } else {
                ProgressView(l10n["dashboard.loading"])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Stats Tab

    private var statsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let stat = vm.stats.first {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        statCard(title: l10n["container.detail.memory.usage"], value: stat.memoryUsageFormatted, detail: "\(l10n["common.of"]) \(stat.memoryLimitFormatted)", color: .blue)
                        statCard(title: l10n["container.detail.memory.percent"], value: String(format: "%.1f%%", stat.memoryUsagePercent), detail: "", color: .green)
                        statCard(title: l10n["container.detail.cpu.time"], value: stat.cpuUsageFormatted, detail: "", color: .orange)
                        statCard(title: l10n["container.detail.network.rx"], value: ByteCountFormatter.string(fromByteCount: Int64(stat.networkRxBytes ?? 0), countStyle: .file), detail: "", color: .purple)
                        statCard(title: l10n["container.detail.network.tx"], value: ByteCountFormatter.string(fromByteCount: Int64(stat.networkTxBytes ?? 0), countStyle: .file), detail: "", color: .purple)
                        statCard(title: l10n["container.detail.processes"], value: "\(stat.numProcesses ?? 0)", detail: "", color: .gray)
                    }
                    .padding()

                    // Memory bar
                    if let stat = vm.stats.first {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(l10n["container.detail.memory.usage"])
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ProgressView(value: stat.memoryUsagePercent / 100)
                                .tint(stat.memoryUsagePercent > 80 ? .red : .blue)
                            Text("\(stat.memoryUsageFormatted) / \(stat.memoryLimitFormatted)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    ContentUnavailableView(
                        l10n["container.detail.stats.none"],
                        systemImage: "chart.bar",
                        description: Text(l10n["container.detail.stats.waiting"])
                    )
                }
            }
        }
    }

    private func statCard(title: String, value: String, detail: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.title3, design: .rounded).bold())
                .foregroundColor(color)
            if !detail.isEmpty {
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DT.smallCardRadius))
    }

    // MARK: - Logs Tab

    private var logsView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(l10n["container.detail.logs.title"])
                    .font(.headline)
                Spacer()
                Button {
                    Task { await vm.refreshLogs(id: containerId) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help(l10n["container.detail.logs.refresh"])
            }
            .padding()

            ScrollViewReader { proxy in
                ScrollView {
                    Text(vm.logs.isEmpty ? l10n["container.detail.logs.empty"] : vm.logs)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding()
                }
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.bottom)
                .overlay {
                    if vm.isLoadingLogs {
                        ProgressView()
                    }
                }
            }
        }
    }
}

// MARK: - Detail Tab Localization

extension ContainerDetailViewModel.DetailTab {
    func localizedName(using l10n: LocalizationManager) -> String {
        switch self {
        case .inspect: return l10n["container.detail.inspect"]
        case .stats: return l10n["container.detail.stats"]
        case .logs: return l10n["container.detail.logs"]
        }
    }
}
