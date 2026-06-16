import Foundation

@MainActor
class ImageListViewModel: ObservableObject {
    @Published var images: [ImageListItemModel] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var pullReference = ""
    @Published var isPulling = false
    @Published var pullingImages: [String] = [] // references being pulled

    private let service = ContainerService.shared

    var filteredImages: [ImageListItemModel] {
        var result = images

        // Show pulling placeholders at top
        for ref in pullingImages {
            let placeholder = ImageListItemModel.placeholder(reference: ref)
            if !result.contains(where: { $0.id == placeholder.id }) {
                result.insert(placeholder, at: 0)
            }
        }

        if searchText.isEmpty { return result }
        return result.filter {
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
        let ref = pullReference.trimmingCharacters(in: .whitespaces)
        guard !ref.isEmpty else {
            errorMessage = "Please enter an image reference."
            return
        }
        isPulling = true
        errorMessage = nil
        pullReference = ""
        pullingImages.append(ref)

        do {
            try await service.pullImage(reference: ref)
            pullingImages.removeAll { $0 == ref }
            await refresh()
        } catch {
            pullingImages.removeAll { $0 == ref }
            errorMessage = error.localizedDescription
            await refresh()
        }
        isPulling = false
    }
}
