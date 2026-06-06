import Combine
import CoreLocation
import WanderpastCore

/// Wraps CoreLocation for discovery — separate from `LiveGeofenceManager`, which is
/// for waypoint triggering during a tour. This one publishes the current `whenInUse`
/// authorization state and a coarse, low-power user location.
@MainActor
final class LiveLocationProvider: NSObject, ObservableObject {
    @Published private(set) var authorization: LocationAuthorization = .notDetermined
    @Published private(set) var userLocation: Coordinate?

    private let locationManager: CLLocationManager

    override init() {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 250
        self.locationManager = manager
        super.init()
        locationManager.delegate = self
        authorization = Self.map(locationManager.authorizationStatus)
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        guard authorization == .granted else { return }
        locationManager.startUpdatingLocation()
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }

    fileprivate static func map(_ status: CLAuthorizationStatus) -> LocationAuthorization {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorizedAlways, .authorizedWhenInUse: return .granted
        @unknown default: return .notDetermined
        }
    }
}

extension LiveLocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = Self.map(status)
            if self.authorization == .granted {
                self.startUpdating()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        let coord = Coordinate(latitude: last.coordinate.latitude, longitude: last.coordinate.longitude)
        Task { @MainActor in
            self.userLocation = coord
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Surface no-fix as a stalled .locating state — the VM can choose how to handle.
    }
}
