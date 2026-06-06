import Foundation

/// Location authorization, decoupled from CoreLocation so it can live in the pure layer.
public enum LocationAuthorization: Equatable, Sendable {
    case notDetermined
    case denied
    case restricted
    case granted
}

public enum NearbyToursState: Equatable, Sendable {
    /// User hasn't (or can't) grant permission. The section is omitted from the UI.
    case hidden
    /// Permission granted, waiting on the first location fix or catalogue load.
    case locating
    case loaded([NearbyTour])
    case error(retryable: Bool)

    /// Pure mapping from authorization + last-known location + catalogue load result to
    /// the "Near you" section's state. `loadResult` is nil while the catalogue is still
    /// loading; `userLocation` is nil until the first fix lands.
    public static func from(
        authorization: LocationAuthorization,
        userLocation: Coordinate?,
        loadResult: CatalogueRepository.LoadResult?,
        radiusMeters: Double?
    ) -> NearbyToursState {
        guard authorization == .granted else { return .hidden }
        guard let userLocation else { return .locating }
        guard let loadResult else { return .locating }
        switch loadResult {
        case .fresh(let catalogue):
            return .loaded(catalogue.nearbyTours(from: userLocation, within: radiusMeters))
        case .cached(let catalogue, _):
            return .loaded(catalogue.nearbyTours(from: userLocation, within: radiusMeters))
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
