import SwiftUI
import AppKit

struct ContainerCreateView: View {
    @EnvironmentObject var l10n: LocalizationManager
    @StateObject private var vm = ContainerCreateViewModel()
    let onCreated: (String) -> Void
    let onCancel: () -> Void

    @State private var newEnvKey = ""
    @State private var newEnvValue = ""
    @State private var newPortHost = ""
    @State private var newPortContainer = ""
    @State private var newVolumeHost = ""
    @State private var newVolumeContainer = ""

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case image, name, command
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(l10n["container.create.title"])
                    .font(.title2)
                    .bold()

                Spacer()

                Button(l10n["container.create.cancel"]) {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button(l10n["container.create.submit"]) {
                    Task { await vm.create() }
                }
                .disabled(vm.imageName.isEmpty || vm.isCreating)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            // Form content
            ScrollView {
                Form {
                    // Basic settings
                    Section(l10n["container.create.basic"]) {
                        TextField(l10n["container.create.image"], text: $vm.imageName)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .image)

                        TextField(l10n["container.create.name"], text: $vm.containerName)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .name)

                        TextField(l10n["container.create.command"], text: $vm.command)
                            .textFieldStyle(.roundedBorder)
                            .help(l10n["container.create.command.hint"])
                            .focused($focusedField, equals: .command)
                    }

                    // Resources
                    Section(l10n["container.create.resources"]) {
                        HStack {
                            Stepper(l10n.format("container.create.cpus", ["count": "\(vm.cpus)"]), value: $vm.cpus, in: 1...32)
                                .frame(maxWidth: 220)

                            Spacer()

                            HStack {
                                Text(l10n["container.create.memory"] + ":")
                                    .font(.caption)
                                TextField("", text: $vm.memory)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                            }
                            Text(l10n["container.create.memory.hint"])
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Network
                    Section(l10n["container.create.network"]) {
                        TextField(l10n["container.create.network.name"], text: $vm.network)
                            .textFieldStyle(.roundedBorder)

                        ForEach(vm.ports.indices, id: \.self) { index in
                            HStack {
                                TextField(l10n["container.create.port"], text: $vm.ports[index])
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption)
                                    .monospaced()
                                Button {
                                    vm.ports.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack {
                            TextField(l10n["container.create.host_port"], text: $newPortHost)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            Text(":").foregroundColor(.secondary)
                            TextField(l10n["container.create.container_port"], text: $newPortContainer)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            Button {
                                let spec = "\(newPortHost):\(newPortContainer)"
                                if !newPortHost.isEmpty && !newPortContainer.isEmpty {
                                    vm.ports.append(spec)
                                    newPortHost = ""
                                    newPortContainer = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(.plain)
                            .disabled(newPortHost.isEmpty || newPortContainer.isEmpty)
                        }
                    }

                    // Volumes
                    Section(l10n["container.create.volumes"]) {
                        ForEach(vm.volumes.indices, id: \.self) { index in
                            HStack {
                                TextField(l10n["container.create.volume.path"], text: $vm.volumes[index])
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption)
                                    .monospaced()
                                Button {
                                    vm.volumes.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack {
                            TextField(l10n["container.create.host_path"], text: $newVolumeHost)
                                .textFieldStyle(.roundedBorder)
                            Text(":").foregroundColor(.secondary)
                            TextField(l10n["container.create.container_path"], text: $newVolumeContainer)
                                .textFieldStyle(.roundedBorder)
                            Button {
                                if !newVolumeHost.isEmpty && !newVolumeContainer.isEmpty {
                                    vm.volumes.append("\(newVolumeHost):\(newVolumeContainer)")
                                    newVolumeHost = ""
                                    newVolumeContainer = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(.plain)
                            .disabled(newVolumeHost.isEmpty || newVolumeContainer.isEmpty)
                        }
                    }

                    // Environment Variables
                    Section(l10n["container.create.env"]) {
                        ForEach(vm.envVars.indices, id: \.self) { index in
                            HStack {
                                TextField(l10n["container.create.env.entry"], text: $vm.envVars[index])
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption)
                                    .monospaced()
                                Button {
                                    vm.envVars.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack {
                            TextField("KEY", text: $newEnvKey)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                            Text("=").foregroundColor(.secondary)
                            TextField("VALUE", text: $newEnvValue)
                                .textFieldStyle(.roundedBorder)
                            Button {
                                if !newEnvKey.isEmpty {
                                    vm.envVars.append("\(newEnvKey)=\(newEnvValue)")
                                    newEnvKey = ""
                                    newEnvValue = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(.plain)
                            .disabled(newEnvKey.isEmpty)
                        }
                    }

                    // Options
                    Section(l10n["container.create.options"]) {
                        Toggle(l10n["container.create.rosetta"], isOn: $vm.rosetta)
                        Toggle(l10n["container.create.ssh"], isOn: $vm.ssh)
                        Toggle(l10n["container.create.readonly"], isOn: $vm.readOnly)
                    }
                }
                .formStyle(.grouped)
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                focusedField = .image
            }
        }
        .overlay {
            if vm.isCreating {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                VStack {
                    ProgressView()
                    Text(l10n["container.create.creating"])
                        .padding(.top, 8)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .onChange(of: vm.createdId) { _, newId in
            if let id = newId, !id.isEmpty {
                onCreated(id)
                onCancel()
            }
        }
        .alert(l10n["container.create.error.title"], isPresented: .init(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button(l10n["common.ok"], role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}
