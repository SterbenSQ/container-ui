import Foundation

@MainActor
class ImageListViewModel: ObservableObject {
    @Published var images: [ImageListItemModel] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var pullReference = ""
    @Published var isPulling = false
    @Published var pullingImages: [String] = []      // references being pulled
    @Published var failedPulls: [String: String] = [:] // reference → error message

    private let service = ContainerService.shared

    var filteredImages: [ImageListItemModel] {
        var result = images

        // Failed placeholders at very top
        for (ref, _) in failedPulls {
            let placeholder = ImageListItemModel.placeholder(reference: ref)
            if !result.contains(where: { $0.id == placeholder.id }) {
                result.insert(placeholder, at: 0)
            }
        }

        // Pulling placeholders next
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

    /// Get the PullState for a given image
    func pullState(for image: ImageListItemModel) -> PullState {
        guard image.isPlaceholder else { return .none }
        let ref = image.name
        if failedPulls[ref] != nil {
            return .failed(failedPulls[ref]!)
        }
        if pullingImages.contains(ref) {
            return .pulling
        }
        return .none
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
        guard !ref.isEmpty else { return }
        pullReference = ""
        await pull(reference: ref)
    }

    func retryPull(reference: String) async {
        failedPulls.removeValue(forKey: reference)
        await pull(reference: reference)
    }

    func removeFailedPull(reference: String) {
        failedPulls.removeValue(forKey: reference)
    }

    private func pull(reference: String) async {
        isPulling = true
        errorMessage = nil
        pullingImages.append(reference)

        do {
            try await service.pullImage(reference: reference)
            pullingImages.removeAll { $0 == reference }
            await refresh()
        } catch {
            pullingImages.removeAll { $0 == reference }
            failedPulls[reference] = error.localizedDescription
        }
        isPulling = false
    }
}
