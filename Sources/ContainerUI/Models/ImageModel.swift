import Foundation

// MARK: - Image List Item (from `image list --format json`)

struct ImageListItemModel: Decodable, Identifiable {
    let id: String
    let configuration: ImageConfigModel
    let variants: [ImageVariantModel]?

    /// Placeholder used while pulling an image (not from JSON)
    static func placeholder(reference: String) -> ImageListItemModel {
        ImageListItemModel(
            id: "__pulling_\(reference)",
            configuration: ImageConfigModel(
                creationDate: Date(),
                name: reference,
                descriptor: ImageDescriptorModel(digest: "pulling...", mediaType: "")
            ),
            variants: nil
        )
    }

    /// Whether this is a synthetic placeholder row
    var isPlaceholder: Bool { id.hasPrefix("__pulling_") }

    var name: String { configuration.name }
    var shortName: String {
        // Strip registry prefix for display
        name.replacingOccurrences(of: "docker.io/library/", with: "")
    }
    var creationDate: Date { configuration.creationDate }

    var totalSize: Int64 {
        variants?.reduce(0) { $0 + $1.size } ?? 0
    }

    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var platforms: String {
        guard let variants = variants else { return "—" }
        return variants.map { "\($0.platform.os)/\($0.platform.architecture)" }
            .joined(separator: ", ")
    }
}

// MARK: - Sub-models

struct ImageConfigModel: Decodable {
    let creationDate: Date
    let name: String
    let descriptor: ImageDescriptorModel
}

struct ImageDescriptorModel: Decodable {
    let digest: String
    let mediaType: String
}

struct ImageVariantModel: Decodable {
    let platform: PlatformModel
    let digest: String
    let size: Int64
    let config: ImageOciConfigModel?
}

struct PlatformModel: Decodable {
    let os: String
    let architecture: String
    let variant: String?
}

struct ImageOciConfigModel: Decodable {
    let created: String?
    let architecture: String?
    let os: String?
}
