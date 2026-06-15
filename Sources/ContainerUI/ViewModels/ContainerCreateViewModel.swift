import Foundation

@MainActor
class ContainerCreateViewModel: ObservableObject {
    @Published var imageName = ""
    @Published var containerName = ""
    @Published var cpus = 4
    @Published var memory = "1g"
    @Published var envVars: [String] = []
    @Published var ports: [String] = []
    @Published var volumes: [String] = []
    @Published var network = ""
    @Published var command = ""
    @Published var rosetta = false
    @Published var ssh = false
    @Published var readOnly = false

    @Published var isCreating = false
    @Published var createdId: String?
    @Published var errorMessage: String?

    private let service = ContainerService.shared

    func create() async {
        guard !imageName.isEmpty else {
            errorMessage = "Image name is required."
            return
        }
        isCreating = true
        errorMessage = nil
        createdId = nil
        do {
            let cmdParts = command.isEmpty ? [] : command.split(separator: " ").map(String.init)
            let id = try await service.createContainer(
                image: imageName,
                name: containerName.isEmpty ? nil : containerName,
                cpus: cpus,
                memory: memory,
                env: envVars.filter { !$0.isEmpty },
                ports: ports.filter { !$0.isEmpty },
                volumes: volumes.filter { !$0.isEmpty },
                command: cmdParts,
                rosetta: rosetta,
                ssh: ssh,
                readOnly: readOnly,
                network: network.isEmpty ? nil : network
            )
            createdId = id
        } catch {
            errorMessage = error.localizedDescription
        }
        isCreating = false
    }

    func reset() {
        imageName = ""
        containerName = ""
        cpus = 4
        memory = "1g"
        envVars = []
        ports = []
        volumes = []
        network = ""
        command = ""
        rosetta = false
        ssh = false
        readOnly = false
        createdId = nil
        errorMessage = nil
    }
}
