import SwiftUI
import WanderpastCore

/// Bridges TourService (pure logic) with real AudioEngine and GeofenceManager.
/// This is the single object SwiftUI views observe for tour state.
@MainActor
final class TourCoordinator: ObservableObject {
    @Published private(set) var service = TourService()

    let audioEngine = AudioEngine()
    let geofenceManager = LiveGeofenceManager()

    private var catalogue: Catalogue?
    private var waypoints: [Waypoint] = []

    /// Map from waypoint ID to its bundled audio filename (without extension)
    private var waypointAudioFiles: [String: String] = [:]
    private var transitionAudioFiles: [String: String] = [:]

    init() {
        // Wire callbacks
        audioEngine.onWaypointFinished = { [weak self] in
            Task { @MainActor in self?.handleWaypointAudioFinished() }
        }
        audioEngine.onTransitionFinished = { [weak self] in
            Task { @MainActor in self?.handleTransitionFinished() }
        }
        geofenceManager.onWaypointTriggered = { [weak self] id in
            Task { @MainActor in self?.handleWaypointTriggered(id) }
        }
    }

    // MARK: - Public API

    func startTour() {
        let content = SampleData.load()
        catalogue = content
        let tour = content.tours[0]
        waypoints = content.waypoints.sorted { $0.order < $1.order }

        // Build manifest for the pure state machine
        let manifest = TourManifest(waypoints: waypoints.map {
            TourManifest.Waypoint(
                id: $0.id,
                latitude: $0.latitude,
                longitude: $0.longitude,
                radius: $0.triggerRadiusM
            )
        })

        // Build audio file lookup from URL filenames
        for wp in waypoints {
            let audioFilename = wp.audioURL.deletingPathExtension().lastPathComponent
            waypointAudioFiles[wp.id] = audioFilename
            if let transitionURL = wp.transitionAudioURL {
                transitionAudioFiles[wp.id] = transitionURL.deletingPathExtension().lastPathComponent
            }
        }

        // Build waypoint title lookup
        var titles: [String: String] = [:]
        for wp in waypoints { titles[wp.id] = wp.title }

        // Start the pure state machine (checkpoint disabled during development)
        service.startTour(tour: manifest)

        // Start the real audio
        audioEngine.startTour(
            waypointIDs: waypoints.map(\.id),
            ambientFile: "ambient",
            tourTitle: tour.title,
            waypointTitles: titles
        )

        // Start the real geofences
        geofenceManager.requestPermission()
        let regions = waypoints.map {
            WaypointRegion(id: $0.id, latitude: $0.latitude, longitude: $0.longitude, radius: $0.triggerRadiusM)
        }
        geofenceManager.startTour(waypoints: regions)
    }

    func pause() {
        service.pause()
        audioEngine.togglePause()
        objectWillChange.send()
    }

    func resume() {
        service.resume()
        audioEngine.togglePause()
        objectWillChange.send()
    }

    func skipForward() {
        if service.currentWaypointID == nil {
            // No waypoint playing yet — trigger the first uncompleted one
            let completedSet = Set(service.completedWaypointIDs)
            if let next = waypoints.first(where: { !completedSet.contains($0.id) }) {
                handleWaypointTriggered(next.id)
            }
        } else {
            service.skipForward()
            audioEngine.skipForward()
            if let id = service.currentWaypointID, let file = waypointAudioFiles[id] {
                audioEngine.triggerWaypoint(id: id, audioFile: file)
            }
        }
        objectWillChange.send()
    }

    func skipBackward() {
        service.skipBackward()
        audioEngine.skipBackward()
        if let id = service.currentWaypointID, let file = waypointAudioFiles[id] {
            audioEngine.triggerWaypoint(id: id, audioFile: file)
        }
        objectWillChange.send()
    }

    // MARK: - State accessors for the UI

    var tourStatus: TourStatus { service.tourStatus }
    var phase: TourPhase { service.phase }
    var isPaused: Bool { service.audioState.isPaused }

    var currentWaypointTitle: String? {
        guard let id = service.currentWaypointID else { return nil }
        return waypoints.first(where: { $0.id == id })?.title
    }

    var completedCount: Int { service.completedWaypointIDs.count }
    var totalWaypoints: Int { waypoints.count }

    // MARK: - Event handlers

    private func handleWaypointTriggered(_ id: String) {
        service.onWaypointEntered(id: id)
        if let file = waypointAudioFiles[id] {
            audioEngine.triggerWaypoint(id: id, audioFile: file)
        }
        objectWillChange.send()
    }

    private func handleWaypointAudioFinished() {
        let justCompletedID = service.currentWaypointID
        service.onWaypointAudioFinished()

        // Play transition audio if available
        if let id = justCompletedID, let file = transitionAudioFiles[id] {
            audioEngine.playTransition(audioFile: file)
        } else {
            // No transition audio — go directly to next phase
            handleTransitionFinished()
        }

        saveCheckpoint()
        objectWillChange.send()
    }

    private func handleTransitionFinished() {
        service.onTransitionAudioFinished()
        saveCheckpoint()
        objectWillChange.send()
    }

    // MARK: - Persistence (UserDefaults)

    private func saveCheckpoint() {
        // Disabled during development — re-enable for production
        // guard let tour = catalogue?.tours.first else { return }
        // UserDefaults.standard.set(service.completedWaypointIDs.count, forKey: "checkpoint_\(tour.id)")
    }

    private func loadCheckpoint(tourID: String) -> Int {
        UserDefaults.standard.integer(forKey: "checkpoint_\(tourID)")
    }
}
