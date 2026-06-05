import Foundation
import WanderpastCore

/// Wraps a CatalogueRepository and publishes a SwiftUI-friendly tour-list state for a single city.
/// All mapping is delegated to `TourListState.from(loadResult:cityID:)` in WanderpastCore.
@MainActor
final class TourListViewModel: ObservableObject {
    @Published private(set) var state: TourListState = .loading

    let cityID: String
    private let repository: CatalogueRepository
    private var loadTask: Task<Void, Never>?

    init(cityID: String, repository: CatalogueRepository) {
        self.cityID = cityID
        self.repository = repository
    }

    deinit {
        loadTask?.cancel()
    }

    func load() {
        loadTask?.cancel()
        state = .loading
        let cityID = self.cityID
        loadTask = Task { [repository] in
            for await result in repository.loadCatalogue() {
                if Task.isCancelled { return }
                self.state = TourListState.from(loadResult: result, cityID: cityID)
            }
        }
    }

    func retry() {
        load()
    }
}
