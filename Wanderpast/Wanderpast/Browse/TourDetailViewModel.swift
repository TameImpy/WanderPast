import Foundation
import WanderpastCore

/// Wraps a CatalogueRepository and publishes a SwiftUI-friendly state for a single tour's detail screen.
/// All mapping is delegated to `TourDetailState.from(loadResult:tourID:)` in WanderpastCore.
@MainActor
final class TourDetailViewModel: ObservableObject {
    @Published private(set) var state: TourDetailState = .loading

    let tourID: String
    private let repository: CatalogueRepository
    private var loadTask: Task<Void, Never>?

    init(tourID: String, repository: CatalogueRepository) {
        self.tourID = tourID
        self.repository = repository
    }

    deinit {
        loadTask?.cancel()
    }

    func load() {
        loadTask?.cancel()
        state = .loading
        let tourID = self.tourID
        loadTask = Task { [repository] in
            for await result in repository.loadCatalogue() {
                if Task.isCancelled { return }
                self.state = TourDetailState.from(loadResult: result, tourID: tourID)
            }
        }
    }

    func retry() {
        load()
    }
}
