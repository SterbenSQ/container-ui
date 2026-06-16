import Foundation

struct CommandEntry: Identifiable, Equatable {
    let id = UUID()
    let command: String
    let output: String
    let isError: Bool
}

@MainActor
final class ContainerExecViewModel: ObservableObject {
    let containerId: String
    let containerName: String

    @Published var commandInput = ""
    @Published var history: [CommandEntry] = []
    @Published var isExecuting = false
    @Published var errorMessage: String?

    private let service = ContainerService.shared

    init(containerId: String, containerName: String) {
        self.containerId = containerId
        self.containerName = containerName
    }

    func executeCommand() async {
        let cmd = commandInput.trimmingCharacters(in: .whitespaces)
        guard !cmd.isEmpty else { return }

        let components = cmd.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard let executable = components.first else { return }

        let args = Array(components.dropFirst())
        isExecuting = true
        commandInput = ""

        do {
            let result = try await service.exec(
                containerId: containerId,
                command: [executable] + args
            )
            let entry = CommandEntry(command: cmd, output: result, isError: false)
            history.append(entry)
        } catch {
            let entry = CommandEntry(
                command: cmd,
                output: error.localizedDescription,
                isError: true
            )
            history.append(entry)
        }
        isExecuting = false
    }
}
