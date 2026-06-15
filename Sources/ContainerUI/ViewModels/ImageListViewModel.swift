import Foundation

@MainActor
class ImageListViewModel: ObservableObject {
    @Published var images: [ImageListItemModel] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var pullReference = ""
    @Published var isPulling = false
    @Published var pullResult: String?

    private let service = ContainerService.shared

    var filteredImages: [ImageListItemModel] {
        if searchText.isEmpty { return images }
        return images.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            images = try await service.listImages()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteImage(reference: String) async {
        do {
            _ = try await service.deleteImage(reference: reference)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func pullImage() async {
        guard !pullReference.isEmpty else {
            errorMessage = "Please enter an image reference."
            return
        }
        isPulling = true
        errorMessage = nil
        pullResult = nil
        do {
            try await service.pullImage(reference: pullReference)
            pullResult = "Successfully pulled \(pullReference)"
            pullReference = ""
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
        isPulling = false
    }
}
