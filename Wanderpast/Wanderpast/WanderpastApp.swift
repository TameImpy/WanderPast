import SwiftUI
import WanderpastCore

@main
struct WanderpastApp: App {
    @StateObject private var coordinator: TourCoordinator
    @StateObject private var tourDetailVM: TourDetailViewModel

    /// The Tower of London tour is hardcoded as the launch destination during Slice 9.
    /// Slice 10 replaces this with `CityBrowseView` and full navigation.
    private static let launchTourID = "tower-of-london-prisoners"

    init() {
        let repository = Self.makeRepository()
        _coordinator = StateObject(wrappedValue: TourCoordinator())
        _tourDetailVM = StateObject(
            wrappedValue: TourDetailViewModel(tourID: Self.launchTourID, repository: repository)
        )
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TourDetailView(viewModel: tourDetailVM, coordinator: coordinator)
            }
        }
    }

    private static func makeRepository() -> CatalogueRepository {
        let cacheDir = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("catalogue")
        let cache = CatalogueCache(directory: cacheDir)
        let fetcher = CatalogueFetcher()
        let url = URL(string: "https://raw.githubusercontent.com/TameImpy/WanderPast/main/Wanderpast/Resources/catalogue.json")!
        return CatalogueRepository(fetcher: fetcher, cache: cache, url: url)
    }
}
