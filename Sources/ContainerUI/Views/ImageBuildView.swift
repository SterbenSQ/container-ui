import SwiftUI

struct ImageBuildView: View {
    @EnvironmentObject var l10n: LocalizationManager
    @StateObject private var vm = ImageBuildViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section(l10n["image.build.settings"]) {
                    HStack {
                        TextField(l10n["image.build.tag"], text: $vm.tag)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            vm.selectDirectory()
                        } label: {
                            Label(l10n["image.build.select"], systemImage: "folder")
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.secondary)
                        Text(vm.directoryName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        if vm.selectedDirectory != nil {
                            Button {
                                vm.selectedDirectory = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Section(l10n["image.build.log"]) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(vm.buildLog.isEmpty ? l10n["image.build.log.empty"] : vm.buildLog)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .padding()
                        }
                        .frame(minHeight: 200, maxHeight: 300)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(l10n["image.build.title"])
            .toolbar {
                ToolbarItemGroup {
                    if vm.isComplete {
                        Button {
                            vm.reset()
                        } label: {
                            Label(l10n["image.build.new"], systemImage: "plus")
                        }
                    }

                    Button {
                        Task { await vm.build() }
                    } label: {
                        if vm.isBuilding {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Label(l10n["image.build.button"], systemImage: "hammer")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.isBuilding || vm.tag.isEmpty || vm.selectedDirectory == nil)
                }
            }
            .alert(l10n["image.build.error.title"], isPresented: .init(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button(l10n["common.ok"], role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }
}
