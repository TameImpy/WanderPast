import SwiftUI
import WanderpastCore

@main
struct WanderpastApp: App {
    @StateObject private var coordinator = TourCoordinator()
    @StateObject private var cityBrowseVM: CityBrowseViewModel

    private let repository: CatalogueRepository

    init() {
        let repo = Self.makeRepository()
        self.repository = repo
        _cityBrowseVM = StateObject(wrappedValue: CityBrowseViewModel(repository: repo))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CityBrowseView(viewModel: cityBrowseVM, repository: repository)
            }
            .environmentObject(coordinator)
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
