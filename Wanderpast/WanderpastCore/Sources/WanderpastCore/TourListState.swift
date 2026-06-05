import Foundation

public enum TourListState: Equatable, Sendable {
    case loading
    case loaded(editorialPick: Tour?, others: [Tour])
    case error(retryable: Bool)

    /// Pure mapping from a repository load result to a tour-list-screen state for the given city.
    /// The editorial pick is exposed separately so the UI can render a hero card; `others` excludes
    /// the pick to avoid double-rendering.
    public static func from(
        loadResult: CatalogueRepository.LoadResult,
        cityID: String
    ) -> TourListState {
        switch loadResult {
        case .fresh(let catalogue), .cached(let catalogue, _):
            let pick = catalogue.editorialPick(for: cityID)
            let others = catalogue.tours(in: cityID).filter { $0.id != pick?.id }
            return .loaded(editorialPick: pick, others: others)
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
