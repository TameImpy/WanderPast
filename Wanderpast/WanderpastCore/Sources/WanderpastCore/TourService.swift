public struct TourManifest: Sendable {
    public let waypoints: [Waypoint]

    public init(waypoints: [Waypoint]) {
        self.waypoints = waypoints
    }

    public struct Waypoint: Sendable {
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
}

public enum TourStatus: Sendable {
    case notStarted
    case inProgress
    case completed
}

public enum TourPhase: Sendable {
    case idle
    case waitingForWaypoint
    case playingWaypoint
    case playingTransition
}

/// Orchestrates AudioEngineState + GeofenceState into a coherent tour experience.
public struct TourService: Sendable {
    public private(set) var tourStatus: TourStatus = .notStarted
    public private(set) var phase: TourPhase = .idle
    public private(set) var audioState = AudioEngineState()
    public private(set) var geofenceState = GeofenceState()
    public private(set) var currentWaypointID: String?
    public private(set) var completedWaypointIDs: [String] = []

    private var manifest: TourManifest?

    public init() {}

    public mutating func startTour(tour: TourManifest, checkpoint: Int = 0) {
        manifest = tour
        tourStatus = .inProgress

        let waypointIDs = tour.waypoints.map(\.id)
        audioState.startTour(waypoints: waypointIDs)

        let regions = tour.waypoints.map {
            WaypointRegion(id: $0.id, latitude: $0.latitude, longitude: $0.longitude, radius: $0.radius)
        }
        geofenceState.startTour(waypoints: regions)

        // Mark waypoints before the checkpoint as already completed
        completedWaypointIDs = Array(waypointIDs.prefix(checkpoint))

        // Suppress jitter for completed waypoints so they don't re-trigger
        for id in completedWaypointIDs {
            geofenceState.didEnterRegion(id: id)
            geofenceState.consumeTrigger()
        }

        currentWaypointID = nil
        phase = .waitingForWaypoint
    }

    public mutating func onWaypointEntered(id: String) {
        geofenceState.didEnterRegion(id: id)
        geofenceState.consumeTrigger()
        audioState.triggerWaypoint(id: id)
        currentWaypointID = id
        phase = .playingWaypoint
    }

    public mutating func onWaypointAudioFinished() {
        audioState.waypointDidFinishPlaying()
        markCurrentWaypointCompleted()
        phase = .playingTransition
    }

    public mutating func skipForward() {
        markCurrentWaypointCompleted()
        audioState.skipForward()
        geofenceState.manualAdvance()
        if let newID = audioState.currentWaypointID {
            currentWaypointID = newID
            phase = .playingWaypoint
        }
    }

    public mutating func skipBackward() {
        audioState.skipBackward()
        if let newID = audioState.currentWaypointID {
            currentWaypointID = newID
            phase = .playingWaypoint
        }
    }

    public mutating func pause() {
        audioState.togglePause()
    }

    public mutating func resume() {
        audioState.togglePause()
    }

    private mutating func markCurrentWaypointCompleted() {
        if let id = currentWaypointID, !completedWaypointIDs.contains(id) {
            completedWaypointIDs.append(id)
        }
    }

    public mutating func onTransitionAudioFinished() {
        guard let manifest else { return }
        if completedWaypointIDs.count >= manifest.waypoints.count {
            tourStatus = .completed
            phase = .idle
            geofenceState.endTour()
        } else {
            phase = .waitingForWaypoint
        }
    }
}
