import SwiftUI
import AppKit

struct ContainerExecView: View {
    @EnvironmentObject var l10n: LocalizationManager
    @StateObject private var vm: ContainerExecViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool
    @State private var scrolledId: UUID?

    init(containerId: String, containerName: String) {
        _vm = StateObject(wrappedValue: ContainerExecViewModel(
            containerId: containerId,
            containerName: containerName
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Output area
                ScrollViewReader { proxy in
                    ScrollView {
                        if vm.history.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "terminal.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text(l10n["container.exec.hint"])
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("ls, ps aux, cat /etc/os-release…")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .monospaced()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                        }

                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(vm.history) { entry in
                                VStack(alignment: .leading, spacing: 2) {
                                    // Command line
                                    HStack {
                                        Text("$")
                                            .foregroundColor(.green)
                                        Text(entry.command)
                                            .foregroundColor(.white)
                                            .bold()
                                    }
                                    .font(.system(.caption, design: .monospaced))

                                    // Output
                                    Text(entry.output)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(entry.isError ? .red : .primary)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                                .id(entry.id)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: vm.history.last?.id) { _, newId in
                        if let id = newId {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }
                }
                .background(Color.black.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 0))

                Divider()

                // Input area
                HStack(spacing: 8) {
                    Text("$")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)

                    TextField("", text: $vm.commandInput)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .monospaced))
                        .focused($isInputFocused)
                        .onSubmit {
                            Task { await vm.executeCommand() }
                        }
                        .disabled(vm.isExecuting)

                    if vm.isExecuting {
                        ProgressView()
                            .scaleEffect(0.7)
                    }

                    Button {
                        Task { await vm.executeCommand() }
                    } label: {
                        Image(systemName: "return")
                            .font(.caption)
                    }
                    .disabled(vm.commandInput.trimmingCharacters(in: .whitespaces).isEmpty || vm.isExecuting)
                    .keyboardShortcut(.return, modifiers: [])
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(nsColor: .controlBackgroundColor))
            }
            .navigationTitle("\(vm.containerName) — CLI")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l10n["container.list.cancel"]) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !vm.history.isEmpty {
                        Button {
                            vm.history.removeAll()
                        } label: {
                            Label("Clear", systemImage: "eraser")
                        }
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    NSApp.activate(ignoringOtherApps: true)
                    isInputFocused = true
                }
            }
        }
    }
}
