import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var systemStatus: SystemStatusModel?
    @Published var diskUsage: DiskUsageModel?
    @Published var versions: [VersionModel] = []
    @Published var containerCount: Int = 0
    @Published var imageCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = ContainerService.shared

    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            systemStatus = try await service.systemStatus()
        } catch {
            // daemon unreachable → definitely not running
            systemStatus = SystemStatusModel(unreachable: true)
        }
        do {
            diskUsage = try await service.systemDiskUsage()
        } catch {
            // same — can fail if daemon is restarting
        }
        do {
            versions = try await service.systemVersion()
        } catch { }
        do {
            containerCount = try await service.listContainers(all: true).count
        } catch { }
        do {
            imageCount = try await service.listImages().count
        } catch { }
        isLoading = false
    }

    func startSystem() async {
        errorMessage = nil
        do {
            try await service.systemStart()
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        // Wait and retry until daemon is confirmed running
        for _ in 0..<6 {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await refresh()
            if isRunning { return }
        }
    }

    func stopSystem() async {
        errorMessage = nil
        do {
            try await service.systemStop()
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        // Wait and retry until daemon is confirmed stopped
        for _ in 0..<6 {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await refresh()
            if !isRunning { return }
        }
    }

    var isRunning: Bool {
        systemStatus?.status == "running"
    }
}
