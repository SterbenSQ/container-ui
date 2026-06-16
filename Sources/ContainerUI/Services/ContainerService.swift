import Foundation

// MARK: - Errors

enum ContainerError: LocalizedError {
    case cliNotFound
    case systemNotRunning
    case commandFailed(exitCode: Int32, stderr: String, stdout: String)
    case parseFailed(String)

    var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "container CLI not found. Make sure apple/container is installed."
        case .systemNotRunning:
            return "Container system is not running. Please start it first."
        case .commandFailed(let code, let stderr, let stdout):
            let err = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            let out = stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            if !err.isEmpty { return err }
            if !out.isEmpty { return "(exit \(code)) \(out)" }
            return "Command failed (exit \(code))"
        case .parseFailed(let detail):
            return "Failed to parse output: \(detail)"
        }
    }
}

// MARK: - ContainerService

/// Service that wraps the `container` CLI tool via Process.
/// All methods are async and throw on failure.
actor ContainerService {
    static let shared = ContainerService()

    private let cliPath: String

    init(cliPath: String = "/usr/local/bin/container") {
        self.cliPath = cliPath
    }

    // MARK: - Core Execution

    /// Execute a command and return stdout as Data.
    /// Throws if the command fails or the executable is not found, or on timeout (60s).
    /// - Parameter executable: Path to the executable (defaults to `cliPath`).
    private func execute(args: [String], executable: String? = nil) async throws -> Data {
        let exe = executable ?? cliPath
        guard FileManager.default.isExecutableFile(atPath: exe) else {
            throw ContainerError.cliNotFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                // Use temp file to avoid NSPipe hang
                let tempFile = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("containerui_\(UUID().uuidString).txt")
                defer { try? FileManager.default.removeItem(at: tempFile) }

                FileManager.default.createFile(atPath: tempFile.path, contents: nil)
                guard let fh = try? FileHandle(forWritingTo: tempFile) else {
                    continuation.resume(throwing: ContainerError.commandFailed(
                        exitCode: -1, stderr: "Cannot create temp file", stdout: ""))
                    return
                }

                let process = Process()
                process.executableURL = URL(fileURLWithPath: exe)
                process.arguments = args
                process.standardOutput = fh
                process.standardError = fh

                // Timeout after 60s
                let timer = DispatchSource.makeTimerSource()
                timer.schedule(deadline: .now() + 60)
                timer.setEventHandler { process.terminate() }
                timer.resume()

                do {
                    try process.run()
                    process.waitUntilExit()
                    timer.cancel()
                    try fh.close()

                    let data = (try? Data(contentsOf: tempFile)) ?? Data()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    let exitCode = process.terminationStatus

                    if exitCode == SIGTERM {
                        continuation.resume(throwing: ContainerError.commandFailed(
                            exitCode: -1, stderr: "Command timed out after 60s", stdout: output))
                    } else if exitCode == 0 {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: ContainerError.commandFailed(
                            exitCode: exitCode, stderr: output, stdout: ""))
                    }
                } catch {
                    try? fh.close()
                    timer.cancel()
                    continuation.resume(throwing: ContainerError.commandFailed(
                        exitCode: -1, stderr: error.localizedDescription, stdout: ""))
                }
            }
        }
    }

    /// Execute a command and return stdout as trimmed UTF-8 string.
    /// - Parameter executable: Path to the executable (defaults to `cliPath`).
    private func executeString(args: [String], executable: String? = nil) async throws -> String {
        let data = try await execute(args: args, executable: executable)
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// Execute a command and decode JSON from stdout.
    /// - Parameter executable: Path to the executable (defaults to `cliPath`).
    private func executeJSON<T: Decodable>(_ type: T.Type, args: [String], executable: String? = nil) async throws -> T {
        let data = try await execute(args: args, executable: executable)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw ContainerError.parseFailed(error.localizedDescription)
        }
    }

    // MARK: - System

    func systemStatus() async throws -> SystemStatusModel {
        try await executeJSON(SystemStatusModel.self, args: ["system", "status", "--format", "json"])
    }

    func systemDiskUsage() async throws -> DiskUsageModel {
        try await executeJSON(DiskUsageModel.self, args: ["system", "df", "--format", "json"])
    }

    func systemPrune() async throws -> SystemPruneResult {
        try await executeJSON(SystemPruneResult.self, args: ["system", "prune", "--format", "json"])
    }

    func systemVersion() async throws -> [VersionModel] {
        try await executeJSON([VersionModel].self, args: ["system", "version", "--format", "json"])
    }

    /// Start the container system.
    @discardableResult
    func systemStart() async throws -> String {
        let cmd = "\(cliPath) system start 2>&1"
        let output = try await executeRaw(cmd: cmd)
        let lower = output.lowercased()
        if lower.contains("already running") || lower.contains("already started") {
            return "Already running"
        }
        return output
    }

    /// Stop the container system.
    @discardableResult
    func systemStop() async throws -> String {
        let cmd = "\(cliPath) system stop 2>&1"
        let output = try await executeRaw(cmd: cmd)
        let lower = output.lowercased()
        if lower.contains("already stopped") || lower.contains("not running")
            || lower.contains("already") || lower.contains("skipping") || lower.contains("health check failed")
        {
            return "Already stopped"
        }
        return output
    }

    // MARK: - Containers

    func listContainers(all: Bool = true) async throws -> [ContainerListItemModel] {
        var args = ["list", "--format", "json"]
        if all {
            args.append("--all")
        }
        return try await executeJSON([ContainerListItemModel].self, args: args)
    }

    func createContainer(
        image: String,
        name: String? = nil,
        cpus: Int? = nil,
        memory: String? = nil,
        env: [String] = [],
        ports: [String] = [],
        volumes: [String] = [],
        command: [String] = [],
        rosetta: Bool = false,
        ssh: Bool = false,
        readOnly: Bool = false,
        network: String? = nil
    ) async throws -> String {
        var args = ["create"]
        if let name = name, !name.isEmpty {
            args += ["--name", name]
        }
        if let cpus = cpus {
            args += ["--cpus", String(cpus)]
        }
        if let memory = memory, !memory.isEmpty {
            args += ["--memory", memory]
        }
        for e in env where !e.isEmpty {
            args += ["--env", e]
        }
        for p in ports where !p.isEmpty {
            args += ["--publish", p]
        }
        for v in volumes where !v.isEmpty {
            args += ["--volume", v]
        }
        if let network = network, !network.isEmpty {
            args += ["--network", network]
        }
        if rosetta {
            args.append("--rosetta")
        }
        if ssh {
            args.append("--ssh")
        }
        if readOnly {
            args.append("--read-only")
        }
        args.append(image)
        args += command
        return try await executeString(args: args)
    }

    func deleteContainer(id: String, force: Bool = false) async throws -> String {
        let safeId = id.replacingOccurrences(of: "'", with: "'\\''")
        let flag = force ? " --force" : ""
        let cmd = "\(cliPath) rm\(flag) '\(safeId)' 2>&1"
        return try await executeRaw(cmd: cmd)
    }

    func startContainer(id: String) async throws -> String {
        let safeId = id.replacingOccurrences(of: "'", with: "'\\''")
        let cmd = "\(cliPath) start '\(safeId)' 2>&1"
        let output = try await executeRaw(cmd: cmd)
        let lower = output.lowercased()
        if lower.contains("already running") || lower.contains("already started") {
            return "Already running"
        }
        return output
    }

    func stopContainer(id: String) async throws -> String {
        let safeId = id.replacingOccurrences(of: "'", with: "'\\''")
        let cmd = "\(cliPath) stop '\(safeId)' 2>&1"
        let output = try await executeRaw(cmd: cmd)
        let lower = output.lowercased()
        if lower.contains("already stopped") || lower.contains("not running") || lower.contains("no such process") {
            return "Already stopped"
        }
        return output
    }

    /// Execute a raw shell command via `/bin/sh -c`, returns combined stdout+stderr.
    /// Throws on non-zero exit with the full output as the error message.
    private func executeRaw(cmd: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                let tempFile = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("containerui_\(UUID().uuidString).txt")
                defer { try? FileManager.default.removeItem(at: tempFile) }

                FileManager.default.createFile(atPath: tempFile.path, contents: nil)
                guard let fh = try? FileHandle(forWritingTo: tempFile) else {
                    continuation.resume(throwing: ContainerError.commandFailed(
                        exitCode: -1, stderr: "Cannot create temp file", stdout: ""))
                    return
                }

                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/sh")
                process.arguments = ["-c", cmd]
                process.standardOutput = fh
                process.standardError = fh

                do {
                    try process.run()
                    process.waitUntilExit()
                    try fh.close()

                    let raw = try? String(contentsOf: tempFile, encoding: .utf8)
                    let output = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                    if process.terminationStatus == 0 {
                        continuation.resume(returning: output)
                    } else {
                        continuation.resume(throwing: ContainerError.commandFailed(
                            exitCode: process.terminationStatus,
                            stderr: output.isEmpty ? "(no output)" : output,
                            stdout: ""
                        ))
                    }
                } catch {
                    try? fh.close()
                    continuation.resume(throwing: ContainerError.commandFailed(
                        exitCode: -1, stderr: error.localizedDescription, stdout: ""))
                }
            }
        }
    }

    func killContainer(id: String) async throws -> String {
        try await executeString(args: ["kill", id])
    }

    func inspectContainer(id: String) async throws -> [ContainerDetailModel] {
        try await executeJSON([ContainerDetailModel].self, args: ["inspect", id])
    }

    func containerStats() async throws -> [ContainerStatsModel] {
        try await executeJSON([ContainerStatsModel].self, args: ["stats", "--no-stream", "--format", "json"])
    }

    func containerLogs(id: String, tail: Int? = nil, boot: Bool = false) async throws -> String {
        var args = ["logs"]
        if let tail = tail {
            args += ["--tail", String(tail)]
        }
        if boot {
            args.append("--boot")
        }
        args.append(id)
        return try await executeString(args: args)
    }

    func exec(containerId: String, command: [String]) async throws -> String {
        try await executeString(args: ["exec", containerId] + command)
    }

    // MARK: - Images

    func listImages() async throws -> [ImageListItemModel] {
        try await executeJSON([ImageListItemModel].self, args: ["image", "list", "--format", "json"])
    }

    func pullImage(reference: String) async throws {
        _ = try await executeString(args: ["image", "pull", reference])
    }

    func deleteImage(reference: String) async throws -> String {
        try await executeString(args: ["image", "rm", reference])
    }

    func buildImage(tag: String, directory: String, dockerfile: String? = nil) async throws -> String {
        var args = ["build", "-t", tag]
        if let df = dockerfile {
            args.append(contentsOf: ["-f", df])
        }
        args.append(directory)
        return try await executeString(args: args)
    }
}
