import Foundation

@MainActor
class ContainerDetailViewModel: ObservableObject {
    @Published var detail: ContainerDetailModel?
    @Published var stats: [ContainerStatsModel] = []
    @Published var logs: String = ""
    @Published var selectedTab: DetailTab = .inspect

    @Published var isLoadingStats = false
    @Published var isLoadingLogs = false
    @Published var errorMessage: String?

    enum DetailTab: String, CaseIterable, Identifiable {
        case inspect = "Inspect"
        case stats = "Stats"
        case logs = "Logs"

        var id: String { rawValue }
    }

    private let service = ContainerService.shared
    private var statsRefreshTask: Task<Void, Never>?

    func loadDetail(id: String) async {
        errorMessage = nil
        do {
            let details = try await service.inspectContainer(id: id)
            detail = details.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startStatsRefresh(id: String) {
        statsRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshStats(id: id)
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    func stopStatsRefresh() {
        statsRefreshTask?.cancel()
        statsRefreshTask = nil
    }

    func refreshStats(id: String) async {
        isLoadingStats = true
        errorMessage = nil
        do {
            let allStats = try await service.containerStats()
            stats = allStats.filter { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingStats = false
    }

    func loadLogs(id: String, tail: Int? = 100) async {
        isLoadingLogs = true
        errorMessage = nil
        do {
            logs = try await service.containerLogs(id: id, tail: tail)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingLogs = false
    }

    func refreshLogs(id: String) async {
        await loadLogs(id: id, tail: 100)
    }

}
