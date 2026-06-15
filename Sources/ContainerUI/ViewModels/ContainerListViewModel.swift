import Foundation
import Combine

@MainActor
class ContainerListViewModel: ObservableObject {
    @Published var containers: [ContainerListItemModel] = []
    @Published var selectedContainer: ContainerListItemModel?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAll = true
    @Published var searchText = ""

    private let service = ContainerService.shared
    private var refreshTask: Task<Void, Never>?

    var filteredContainers: [ContainerListItemModel] {
        var result = containers
        if !showAll {
            result = result.filter { $0.isRunning }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.image.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    func startAutoRefresh() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            containers = try await service.listContainers(all: true)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteContainer(id: String, force: Bool = false) async {
        do {
            _ = try await service.deleteContainer(id: id, force: force)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startContainer(id: String) async {
        errorMessage = nil
        do {
            // If container still stopping, wait briefly and retry
            for attempt in 1...3 {
                do {
                    _ = try await service.startContainer(id: id)
                    await refresh()
                    return
                } catch {
                    let msg = error.localizedDescription.lowercased()
                    if (msg.contains("stopping") || msg.contains("busy") || msg.contains("already"))
                        && attempt < 3
                    {
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s
                        continue
                    }
                    throw error
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopContainer(id: String) async {
        errorMessage = nil
        do {
            _ = try await service.stopContainer(id: id)
            // Brief wait so the daemon updates the container state
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func killContainer(id: String) async {
        do {
            _ = try await service.killContainer(id: id)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
