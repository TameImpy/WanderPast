public enum Interruption: Sendable {
    case began
    case ended(shouldResume: Bool)
}

public enum RouteChange: Sendable {
    case headphonesUnplugged
}

/// Pure state machine for audio playback logic.
/// No AVFoundation dependency — the real AudioEngine reads this state
/// and translates it into framework calls.
public struct AudioEngineState: Sendable {
    public private(set) var isAmbientPlaying = false
    public private(set) var ambientVolume: Float = 0.0
    public private(set) var isWaypointPlaying = false
    public private(set) var currentWaypointID: String?
    public private(set) var isPaused = false

    private static let dippedVolume: Float = 0.15

    private var waypoints: [String] = []
    private var currentWaypointIndex: Int?
    private var wasWaypointPlayingBeforePause = false

    public init() {}

    public mutating func startTour(waypoints: [String]) {
        self.waypoints = waypoints
        isAmbientPlaying = true
        ambientVolume = 1.0
        isWaypointPlaying = false
        currentWaypointID = nil
        isPaused = false
    }

    public mutating func triggerWaypoint(id: String) {
        currentWaypointIndex = waypoints.firstIndex(of: id)
        playWaypoint(id: id)
    }

    public mutating func waypointDidFinishPlaying() {
        isWaypointPlaying = false
        currentWaypointID = nil
        ambientVolume = 1.0
    }

    public mutating func togglePause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }

    public mutating func skipForward() {
        guard let index = currentWaypointIndex,
              index + 1 < waypoints.count else { return }
        let nextIndex = index + 1
        currentWaypointIndex = nextIndex
        playWaypoint(id: waypoints[nextIndex])
    }

    public mutating func skipBackward() {
        guard let index = currentWaypointIndex,
              index - 1 >= 0 else { return }
        let prevIndex = index - 1
        currentWaypointIndex = prevIndex
        playWaypoint(id: waypoints[prevIndex])
    }

    public mutating func handleRouteChange(_ change: RouteChange) {
        switch change {
        case .headphonesUnplugged:
            pause()
        }
    }

    public mutating func handleInterruption(_ interruption: Interruption) {
        switch interruption {
        case .began:
            pause()
        case .ended(let shouldResume):
            if shouldResume {
                resume()
            }
        }
    }

    private mutating func playWaypoint(id: String) {
        currentWaypointID = id
        isWaypointPlaying = true
        ambientVolume = Self.dippedVolume
    }

    private mutating func pause() {
        guard !isPaused else { return }
        isPaused = true
        wasWaypointPlayingBeforePause = isWaypointPlaying
        isAmbientPlaying = false
        isWaypointPlaying = false
    }

    private mutating func resume() {
        guard isPaused else { return }
        isPaused = false
        isAmbientPlaying = true
        if wasWaypointPlayingBeforePause {
            isWaypointPlaying = true
        }
    }
}
