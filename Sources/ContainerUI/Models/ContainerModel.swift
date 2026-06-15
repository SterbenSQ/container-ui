import Foundation

// MARK: - Container List Item (from `container list --format json`)

struct ContainerListItemModel: Decodable, Identifiable {
    let configuration: ContainerConfigModel
    let status: ContainerStatusModel?

    var id: String { configuration.id }

    var name: String { configuration.id }
    var image: String { configuration.image.reference }
    var state: String { status?.state ?? "unknown" }
    var created: Date { configuration.creationDate }
    var ipAddress: String? {
        status?.networks?.first?.ipv4Address
    }
    var startedDate: Date? { status?.startedDate }
}

// MARK: - Container Configuration

struct ContainerConfigModel: Decodable {
    let id: String
    let image: ImageDescriptionModel
    let mounts: [FilesystemModel]?
    let publishedPorts: [PublishPortModel]?
    let labels: [String: String]?
    let networks: [AttachmentConfigModel]?
    let rosetta: Bool?
    let initProcess: ProcessConfigModel
    let resources: ResourcesModel?
    let runtimeHandler: String?
    let virtualization: Bool?
    let ssh: Bool?
    let readOnly: Bool?
    let useInit: Bool?
    let capAdd: [String]?
    let capDrop: [String]?
    let creationDate: Date
}

// MARK: - Sub-models for Container Config

struct ImageDescriptionModel: Decodable {
    let reference: String
    let descriptor: DescriptorModel
}

struct DescriptorModel: Decodable {
    let digest: String
    let mediaType: String
}

struct FilesystemModel: Decodable {
    let source: String?
    let destination: String?
}

struct PublishPortModel: Decodable {
    let hostAddress: String?
    let hostPort: Int
    let containerPort: Int
    let proto: String?
}

struct AttachmentConfigModel: Decodable {
    let network: String
}

struct ProcessConfigModel: Decodable {
    let executable: String
    let arguments: [String]?
    let environment: [String]?
    let workingDirectory: String?
    let terminal: Bool?
    let user: UserModel?
}

struct UserModel: Decodable {
    let id: UIDModel?
}

struct UIDModel: Decodable {
    let uid: UInt32?
    let gid: UInt32?
}

struct ResourcesModel: Decodable {
    let cpus: Int?
    let memoryInBytes: UInt64?
    let storage: UInt64?
    let cpuOverhead: Int?

    var memoryFormatted: String {
        guard let bytes = memoryInBytes else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
}

// MARK: - Container Status

struct ContainerStatusModel: Decodable {
    let state: String
    let networks: [AttachmentModel]?
    let startedDate: Date?
}

struct AttachmentModel: Decodable {
    let network: String?
    let hostname: String?
    let ipv4Address: String?
    let ipv4Gateway: String?
    let ipv6Address: String?
}

// MARK: - Container Detail (from `container inspect id`)

typealias ContainerDetailModel = ContainerListItemModel

// MARK: - Container Stats (from `container stats --no-stream --format json`)

struct ContainerStatsModel: Decodable, Identifiable {
    let id: String
    let memoryUsageBytes: UInt64?
    let memoryLimitBytes: UInt64?
    let cpuUsageUsec: UInt64?
    let networkRxBytes: UInt64?
    let networkTxBytes: UInt64?
    let blockReadBytes: UInt64?
    let blockWriteBytes: UInt64?
    let numProcesses: UInt64?

    var memoryUsageFormatted: String {
        guard let bytes = memoryUsageBytes else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    var memoryLimitFormatted: String {
        guard let bytes = memoryLimitBytes else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    var memoryUsagePercent: Double {
        guard let used = memoryUsageBytes, let limit = memoryLimitBytes, limit > 0 else { return 0 }
        return Double(used) / Double(limit) * 100
    }

    var cpuUsageFormatted: String {
        guard let usec = cpuUsageUsec else { return "—" }
        let seconds = Double(usec) / 1_000_000
        return String(format: "%.2fs", seconds)
    }
}

// MARK: - State Helpers

enum ContainerState: String {
    case running
    case stopped
    case stopping
    case unknown
}

extension ContainerListItemModel {
    var containerState: ContainerState {
        ContainerState(rawValue: state) ?? .unknown
    }

    var stateColor: String {
        switch containerState {
        case .running: return "green"
        case .stopped: return "red"
        case .stopping: return "orange"
        case .unknown: return "gray"
        }
    }

    var isRunning: Bool { containerState == .running }
}
