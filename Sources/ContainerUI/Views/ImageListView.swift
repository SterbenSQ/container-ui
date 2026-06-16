import SwiftUI

struct ImageListView: View {
    @EnvironmentObject var l10n: LocalizationManager
    @StateObject private var vm = ImageListViewModel()
    @State private var confirmDelete: ImageListItemModel?
    @State private var showDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text(l10n["image.list.title"])
                    .font(.largeTitle)
                    .bold()

                Spacer()

                Button {
                    Task { await vm.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help(l10n["dashboard.refresh"])
            }
            .padding()

            // Pull section
            HStack {
                TextField(l10n["image.list.pull.hint"], text: $vm.pullReference)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 400)
                    .onSubmit {
                        Task { await vm.pullImage() }
                    }

                Button {
                    Task { await vm.pullImage() }
                } label: {
                    Label(l10n["image.list.pull"], systemImage: "arrow.down.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.pullReference.isEmpty || vm.isPulling)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(l10n["image.list.search"], text: $vm.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Image list
            List {
                ForEach(vm.filteredImages) { image in
                    ImageRowView(
                        image: image,
                        pullState: vm.pullState(for: image),
                        onRetry: image.isPlaceholder ? { Task { await vm.retryPull(reference: image.name) } } : nil,
                        onRemove: image.isPlaceholder ? { vm.removeFailedPull(reference: image.name) } : nil
                    )
                        .contextMenu {
                            if !image.isPlaceholder {
                                Button(role: .destructive) {
                                    confirmDelete = image
                                    showDeleteAlert = true
                                } label: {
                                    Label(l10n["image.list.delete"], systemImage: "trash")
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            if !image.isPlaceholder {
                                Button(role: .destructive) {
                                    confirmDelete = image
                                    showDeleteAlert = true
                                } label: {
                                    Label(l10n["image.list.delete"], systemImage: "trash")
                                }
                            }
                        }
                }
            }
            .listStyle(.inset)
        }
        .overlay {
            if vm.isLoading && vm.images.isEmpty {
                ProgressView(l10n["dashboard.loading"])
            } else if vm.filteredImages.isEmpty && !vm.isLoading {
                if vm.searchText.isEmpty {
                    ContentUnavailableView(
                        l10n["image.list.empty.title"],
                        systemImage: "photo.stack",
                        description: Text(l10n["image.list.empty.desc"])
                    )
                } else {
                    ContentUnavailableView(
                        l10n["image.list.empty.title"],
                        systemImage: "photo.stack",
                        description: Text(l10n.format("image.list.empty.search", ["text": vm.searchText]))
                    )
                }
            }
        }
        .alert(l10n["image.list.delete.title"], isPresented: $showDeleteAlert, presenting: confirmDelete) { image in
            Button(l10n["image.list.cancel"], role: .cancel) {}
            Button(l10n["image.list.delete"], role: .destructive) {
                Task { await vm.deleteImage(reference: image.name) }
            }
        } message: { image in
            Text(l10n.format("image.list.delete.message", ["name": image.shortName]))
        }
        .task {
            await vm.refresh()
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
}
