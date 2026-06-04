import Foundation
import WanderpastCore

/// Wraps a CatalogueRepository and publishes a SwiftUI-friendly browse state.
/// All mapping is delegated to `CityBrowseState.from(loadResult:)` in WanderpastCore.
@MainActor
final class CityBrowseViewModel: ObservableObject {
    @Published private(set) var state: CityBrowseState = .loading

    private let repository: CatalogueRepository
    private var loadTask: Task<Void, Never>?

    init(repository: CatalogueRepository) {
        self.repository = repository
    }

    deinit {
        loadTask?.cancel()
    }

    func load() {
        loadTask?.cancel()
        state = .loading
        loadTask = Task { [repository] in
            for await result in repository.loadCatalogue() {
                if Task.isCancelled { return }
                self.state = CityBrowseState.from(loadResult: result)
            }
        }
    }

    func retry() {
        load()
    }
}
