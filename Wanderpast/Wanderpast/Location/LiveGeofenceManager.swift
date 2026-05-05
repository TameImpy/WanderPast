import CoreLocation
import WanderpastCore

/// Wraps CoreLocation for GPS waypoint triggering.
/// All decisions are made by GeofenceState — this class just translates
/// state into real CLLocationManager calls.
final class LiveGeofenceManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private(set) var state = GeofenceState()

    var onWaypointTriggered: ((String) -> Void)?

    private var waypointRegions: [WaypointRegion] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - Permissions

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Tour lifecycle

    func startTour(waypoints: [WaypointRegion]) {
        waypointRegions = waypoints
        state.startTour(waypoints: waypoints)

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()

        for wp in waypoints {
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(latitude: wp.latitude, longitude: wp.longitude),
                radius: wp.radius,
                identifier: wp.id
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false
            locationManager.startMonitoring(for: region)
        }
    }

    func endTour() {
        state.endTour()

        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        locationManager.stopUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
    }

    func manualAdvance() {
        state.manualAdvance()
        if let id = state.triggeredWaypointID {
            state.consumeTrigger()
            onWaypointTriggered?(id)
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        state.didEnterRegion(id: region.identifier)
        if let id = state.triggeredWaypointID {
            state.consumeTrigger()
            onWaypointTriggered?(id)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }
}
