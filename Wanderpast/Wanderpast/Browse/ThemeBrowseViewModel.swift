import Foundation
import WanderpastCore

/// Wraps a CatalogueRepository and publishes a SwiftUI-friendly state for the theme/era browse screen.
/// All mapping is delegated to `ThemeBrowseState.from(loadResult:)` in WanderpastCore.
@MainActor
final class ThemeBrowseViewModel: ObservableObject {
    @Published private(set) var state: ThemeBrowseState = .loading

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
                self.state = ThemeBrowseState.from(loadResult: result)
            }
        }
    }

    func retry() {
        load()
    }
}
