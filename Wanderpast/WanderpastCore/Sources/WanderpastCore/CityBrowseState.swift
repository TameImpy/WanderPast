import Foundation

public enum CityBrowseState: Equatable, Sendable {
    case loading
    case loaded([CityRow])
    case error(retryable: Bool)

    /// Pure mapping from a repository load result to a browse-screen state.
    public static func from(loadResult: CatalogueRepository.LoadResult) -> CityBrowseState {
        switch loadResult {
        case .fresh(let catalogue):
            return .loaded(catalogue.cityRows())
        case .cached(let catalogue, _):
            return .loaded(catalogue.cityRows())
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
