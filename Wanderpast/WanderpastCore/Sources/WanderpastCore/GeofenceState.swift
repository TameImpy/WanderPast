public struct WaypointRegion: Sendable {
    public let id: String
    public let latitude: Double
    public let longitude: Double
    public let radius: Double

    public init(id: String, latitude: Double, longitude: Double, radius: Double) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }
}

public enum LocationAccuracy: Sendable {
    case best
    case reduced
}

/// Pure state machine for GPS waypoint triggering logic.
/// No CoreLocation dependency — the real GeofenceManager reads this state
/// and translates it into framework calls.
public struct GeofenceState: Sendable {
    public private(set) var isTourActive = false
    public private(set) var activeWaypointIDs: [String] = []
    public private(set) var currentAccuracy: LocationAccuracy = .reduced
    public private(set) var triggeredWaypointID: String?

    private var waypoints: [WaypointRegion] = []
    private var triggeredIDs: Set<String> = []
    private var lastTriggeredIndex: Int?

    public init() {}

    public mutating func startTour(waypoints: [WaypointRegion]) {
        self.waypoints = waypoints
        activeWaypointIDs = waypoints.map(\.id)
        isTourActive = true
        currentAccuracy = .best
        triggeredWaypointID = nil
        triggeredIDs = []
    }

    public mutating func didEnterRegion(id: String) {
        guard !triggeredIDs.contains(id) else { return }
        triggeredIDs.insert(id)
        triggeredWaypointID = id
        lastTriggeredIndex = waypoints.firstIndex(where: { $0.id == id })
    }

    public mutating func manualAdvance() {
        let nextIndex = (lastTriggeredIndex ?? -1) + 1
        guard nextIndex < waypoints.count else { return }
        let wp = waypoints[nextIndex]
        triggeredIDs.insert(wp.id)
        triggeredWaypointID = wp.id
        lastTriggeredIndex = nextIndex
    }

    public mutating func endTour() {
        isTourActive = false
        activeWaypointIDs = []
        waypoints = []
        currentAccuracy = .reduced
        triggeredWaypointID = nil
        triggeredIDs = []
        lastTriggeredIndex = nil
    }

    public mutating func consumeTrigger() {
        triggeredWaypointID = nil
    }
}
