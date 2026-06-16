import SwiftUI

struct ContainerListView: View {
    @EnvironmentObject var l10n: LocalizationManager
    @StateObject private var vm = ContainerListViewModel()
    @State private var showingCreateSheet = false
    @State private var showingDetail = false
    @State private var showingExec = false
    @State private var selectedForDetail: ContainerListItemModel?
    @State private var selectedForExec: ContainerListItemModel?
    @State private var confirmDelete: ContainerListItemModel?
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Text(l10n["container.list.title"])
                        .font(.largeTitle)
                        .bold()

                    Spacer()

                    Toggle(l10n["container.list.show_all"], isOn: $vm.showAll)
                        .toggleStyle(.checkbox)
                        .help(l10n["container.list.show_all"])

                    Button {
                        showingCreateSheet = true
                    } label: {
                        Label(l10n["container.list.new"], systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        Task { await vm.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help(l10n["dashboard.refresh"])
                }
                .padding()

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(l10n["container.list.search"], text: $vm.searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Container list
                List {
                    ForEach(vm.filteredContainers) { container in
                        ContainerRowView(container: container) {
                            confirmDelete = container
                            showDeleteAlert = true
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedForExec = container
                            showingExec = true
                        }
                        .contextMenu {
                            contextMenu(for: container)
                        }
                        .onTapGesture(count: 2) {
                            selectedForDetail = container
                            showingDetail = true
                        }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    confirmDelete = container
                                    showDeleteAlert = true
                                } label: {
                                    Label(l10n["container.list.delete"], systemImage: "trash")
                                }

                                if container.isRunning {
                                    Button {
                                        Task { await vm.stopContainer(id: container.id) }
                                    } label: {
                                        Label(l10n["container.list.stop"], systemImage: "stop.fill")
                                    }
                                    .tint(.orange)
                                } else {
                                    Button {
                                        Task { await vm.startContainer(id: container.id) }
                                    } label: {
                                        Label(l10n["container.list.start"], systemImage: "play.fill")
                                    }
                                    .tint(.green)
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
            .overlay {
                if vm.isLoading && vm.containers.isEmpty {
                    ProgressView(l10n["dashboard.loading"])
                } else if vm.filteredContainers.isEmpty && !vm.isLoading {
                    if vm.searchText.isEmpty {
                        ContentUnavailableView(
                            l10n["container.list.empty.title"],
                            systemImage: "square.stack.3d.down.right",
                            description: Text(l10n["container.list.empty.desc"])
                        )
                    } else {
                        ContentUnavailableView(
                            l10n["container.list.empty.title"],
                            systemImage: "square.stack.3d.down.right",
                            description: Text(l10n.format("container.list.empty.search", ["text": vm.searchText]))
                        )
                    }
                }
            }

            // Create container overlay — avoids .sheet() focus bug on macOS
            if showingCreateSheet {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { showingCreateSheet = false }
                    .transition(.opacity)

                ContainerCreateView { createdId in
                    if !createdId.isEmpty {
                        showingCreateSheet = false
                        Task { await vm.refresh() }
                    }
                } onCancel: {
                    showingCreateSheet = false
                }
                .frame(minWidth: 550, idealWidth: 580, minHeight: 500, idealHeight: 700)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingCreateSheet)
        .alert(l10n["container.list.delete.title"], isPresented: $showDeleteAlert, presenting: confirmDelete) { container in
            Button(l10n["container.list.cancel"], role: .cancel) {}
            Button(l10n["container.list.delete"], role: .destructive) {
                Task { await vm.deleteContainer(id: container.id, force: true) }
            }
        } message: { container in
            Text(l10n.format("container.list.delete.message", ["name": container.name]))
        }
        .sheet(isPresented: $showingDetail, onDismiss: {
            selectedForDetail = nil
        }) {
            if let container = selectedForDetail {
                ContainerDetailView(containerId: container.id)
            }
        }
        .sheet(isPresented: $showingExec, onDismiss: {
            selectedForExec = nil
        }) {
            if let container = selectedForExec {
                ContainerExecView(containerId: container.id, containerName: container.name)
                    .frame(width: 700, height: 500)
            }
        }
        .task {
            vm.startAutoRefresh()
        }
        .onDisappear {
            vm.stopAutoRefresh()
        }
        .overlay(alignment: .bottom) {
            if let error = vm.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
                    .transition(.move(edge: .bottom))
                    .onTapGesture { vm.errorMessage = nil }
            }
        }
    }

    @ViewBuilder
    private func contextMenu(for container: ContainerListItemModel) -> some View {
        Button {
            selectedForDetail = container
            showingDetail = true
        } label: {
            Label(l10n["container.list.inspect"], systemImage: "info.circle")
        }

        Divider()

        if container.isRunning {
            Button {
                Task { await vm.stopContainer(id: container.id) }
            } label: {
                Label(l10n["container.list.stop"], systemImage: "stop.fill")
            }
            Button {
                Task { await vm.killContainer(id: container.id) }
            } label: {
                Label(l10n["container.list.kill"], systemImage: "bolt.fill")
            }
        } else {
            Button {
                Task { await vm.startContainer(id: container.id) }
            } label: {
                Label(l10n["container.list.start"], systemImage: "play.fill")
            }
        }

        Divider()

        Button(role: .destructive) {
            confirmDelete = container
            showDeleteAlert = true
        } label: {
            Label(l10n["container.list.delete"], systemImage: "trash")
        }
    }
}
