import Foundation

public enum ThemeBrowseState: Equatable, Sendable {
    case loading
    case loaded([EraGroup])
    case error(retryable: Bool)

    /// Pure mapping from a repository load result to a theme-browse-screen state.
    /// Delegates the grouping to `Catalogue.toursGroupedByEra()`, which sorts groups chronologically.
    public static func from(loadResult: CatalogueRepository.LoadResult) -> ThemeBrowseState {
        switch loadResult {
        case .fresh(let catalogue), .cached(let catalogue, _):
            return .loaded(catalogue.toursGroupedByEra())
        case .failure(let error):
            switch error {
            case .offline, .fetchFailed:
                return .error(retryable: true)
            case .parseFailed:
                return .error(retryable: false)
            }
        }
    }
}
