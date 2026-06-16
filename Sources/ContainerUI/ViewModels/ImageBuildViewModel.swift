import Foundation
import AppKit

@MainActor
class ImageBuildViewModel: ObservableObject {
    @Published var tag = ""
    @Published var selectedDirectory: String?
    @Published var selectedDockerfile: String?
    @Published var buildLog: String = ""
    @Published var isBuilding = false
    @Published var isComplete = false
    @Published var errorMessage: String?

    private let service = ContainerService.shared

    var directoryName: String {
        guard let path = selectedDirectory else { return "Not selected" }
        return URL(fileURLWithPath: path).lastPathComponent
    }

    var dockerfileName: String? {
        guard let path = selectedDockerfile else { return nil }
        return URL(fileURLWithPath: path).lastPathComponent
    }

    func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select build context directory"

        let response = panel.runModal()
        if response == .OK, let url = panel.url {
            selectedDirectory = url.path
        }
    }

    func selectDockerfile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [] // any file
        panel.message = "Select Dockerfile"

        let response = panel.runModal()
        if response == .OK, let url = panel.url {
            selectedDockerfile = url.path
        }
    }

    func build() async {
        guard let dir = selectedDirectory else {
            errorMessage = "Please select a build context directory."
            return
        }
        guard !tag.isEmpty else {
            errorMessage = "Please enter an image tag."
            return
        }

        isBuilding = true
        isComplete = false
        errorMessage = nil
        buildLog = "\(tr("image.build.building"))\n"

        do {
            _ = try await service.buildImage(tag: tag, directory: dir, dockerfile: selectedDockerfile)
            buildLog += "\(tr("image.build.success", ["tag": tag]))\n"
            isComplete = true
        } catch {
            buildLog += "\(tr("image.build.failed", ["error": error.localizedDescription]))\n"
            errorMessage = error.localizedDescription
        }
        isBuilding = false
    }

    func reset() {
        tag = ""
        selectedDirectory = nil
        selectedDockerfile = nil
        buildLog = ""
        isBuilding = false
        isComplete = false
        errorMessage = nil
    }
}
