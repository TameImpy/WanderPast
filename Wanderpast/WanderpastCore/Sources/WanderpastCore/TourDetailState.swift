import Foundation

public enum TourDetailState: Equatable, Sendable {
    case loading
    case loaded(Tour, [Waypoint])
    case error(retryable: Bool)
    case notFound

    /// Pure mapping from a repository load result + a target tour ID to a detail-screen state.
    /// `.notFound` is returned when the catalogue parses but doesn't contain the requested tour —
    /// distinct from `.error`, since retrying the network won't help.
    public static func from(
        loadResult: CatalogueRepository.LoadResult,
        tourID: String
    ) -> TourDetailState {
        switch loadResult {
        case .fresh(let catalogue), .cached(let catalogue, _):
            guard let tour = catalogue.tour(id: tourID) else { return .notFound }
            return .loaded(tour, catalogue.waypoints(for: tourID))
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

extension Waypoint: Equatable {
    public static func == (lhs: Waypoint, rhs: Waypoint) -> Bool { lhs.id == rhs.id }
}
