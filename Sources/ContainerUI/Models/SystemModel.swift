import Foundation

// MARK: - System Status (from `system status --format json`)

struct SystemStatusModel: Decodable {
    let status: String
    let appRoot: String?
    let installRoot: String?
    let logRoot: String?
    let apiServerVersion: String?
    let apiServerCommit: String?
    let apiServerBuild: String?
    let apiServerAppName: String?

    /// Fallback initialiser for when the daemon is unreachable.
    init(unreachable: Bool) {
        self.status = "not running"
        self.appRoot = nil
        self.installRoot = nil
        self.logRoot = nil
        self.apiServerVersion = nil
        self.apiServerCommit = nil
        self.apiServerBuild = nil
        self.apiServerAppName = nil
    }

    enum CodingKeys: String, CodingKey {
        case status
        case appRoot
        case installRoot
        case logRoot
        case apiServerVersion
        case apiServerCommit
        case apiServerBuild
        case apiServerAppName
    }
}

// MARK: - Version Info (from `system version --format json`)

struct VersionModel: Decodable {
    let version: String
    let buildType: String?
    let commit: String?
    let appName: String?
}

// MARK: - Disk Usage (from `system df --format json`)

struct DiskUsageModel: Decodable {
    let images: ResourceUsageModel
    let containers: ResourceUsageModel
    let volumes: ResourceUsageModel
}

struct ResourceUsageModel: Decodable {
    let total: Int
    let active: Int
    let sizeInBytes: Int64
    let reclaimable: Int64

    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: sizeInBytes, countStyle: .file)
    }

    var reclaimableFormatted: String {
        ByteCountFormatter.string(fromByteCount: reclaimable, countStyle: .file)
    }
}
