import Testing
@testable import WanderpastCore

@Suite("TourService")
struct TourServiceTests {

    private func makeTwoWaypointTour() -> TourManifest {
        TourManifest(waypoints: [
            TourManifest.Waypoint(id: "wp1", latitude: 51.5074, longitude: -0.1278, radius: 20),
            TourManifest.Waypoint(id: "wp2", latitude: 51.5080, longitude: -0.1280, radius: 25),
        ])
    }

    // MARK: - 1. Start tour

    @Test("Starting a tour plays ambient, registers geofences, and sets status to inProgress")
    func startTour() {
        var service = TourService()
        let tour = makeTwoWaypointTour()

        service.startTour(tour: tour)

        #expect(service.tourStatus == .inProgress)
        #expect(service.audioState.isAmbientPlaying == true)
        #expect(service.audioState.ambientVolume == 1.0)
        #expect(service.geofenceState.isTourActive == true)
        #expect(service.geofenceState.activeWaypointIDs == ["wp1", "wp2"])
        #expect(service.currentWaypointID == nil)
        #expect(service.completedWaypointIDs.isEmpty)
    }

    // MARK: - 2. Waypoint entered

    @Test("Entering a waypoint geofence triggers audio crossfade")
    func waypointEnteredTriggersAudio() {
        var service = TourService()
        service.startTour(tour: makeTwoWaypointTour())

        service.onWaypointEntered(id: "wp1")

        #expect(service.currentWaypointID == "wp1")
        #expect(service.audioState.isWaypointPlaying == true)
        #expect(service.audioState.ambientVolume < 1.0)
        #expect(service.phase == .playingWaypoint)
    }

    // MARK: - 3. Waypoint audio finishes

    @Test("When waypoint audio finishes, waypoint is marked completed and phase becomes playingTransition")
    func waypointAudioFinishes() {
        var service = TourService()
        service.startTour(tour: makeTwoWaypointTour())
        service.onWaypointEntered(id: "wp1")

        service.onWaypointAudioFinished()

        #expect(service.completedWaypointIDs == ["wp1"])
        #expect(service.phase == .playingTransition)
        #expect(service.audioState.isWaypointPlaying == false)
        #expect(service.audioState.ambientVolume == 1.0)
    }

    // MARK: - 4. All waypoints completed

    @Test("Completing all waypoints marks the tour as completed")
    func allWaypointsCompleted() {
        var service = TourService()
        service.startTour(tour: makeTwoWaypointTour())

        // Walk through wp1
        service.onWaypointEntered(id: "wp1")
        service.onWaypointAudioFinished()
        service.onTransitionAudioFinished()

        // Walk through wp2
        service.onWaypointEntered(id: "wp2")
        service.onWaypointAudioFinished()
        service.onTransitionAudioFinished()

        #expect(service.tourStatus == .completed)
        #expect(service.completedWaypointIDs == ["wp1", "wp2"])
    }

    // MARK: - 5. Pause/resume

    @Test("Pause and resume delegate to audio state")
    func pauseResume() {
        var service = TourService()
        service.startTour(tour: makeTwoWaypointTour())
        service.onWaypointEntered(id: "wp1")

        service.pause()

        #expect(service.audioState.isPaused == true)
        #expect(service.audioState.isAmbientPlaying == false)
        #expect(service.audioState.isWaypointPlaying == false)

        service.resume()

        #expect(service.audioState.isPaused == false)
        #expect(service.audioState.isAmbientPlaying == true)
        #expect(service.audioState.isWaypointPlaying == true)
    }

    // MARK: - 6. Skip forward

    @Test("Skip forward advances audio and geofence, marks current waypoint completed")
    func skipForward() {
        var service = TourService()
        service.startTour(tour: makeTwoWaypointTour())
        service.onWaypointEntered(id: "wp1")

        service.skipForward()

        #expect(service.currentWaypointID == "wp2")
        #expect(service.audioState.currentWaypointID == "wp2")
        #expect(service.audioState.isWaypointPlaying == true)
        #expect(service.completedWaypointIDs == ["wp1"])
        #expect(service.phase == .playingWaypoint)
    }

    // MARK: - 7. Resume from checkpoint

    @Test("Starting a tour with a checkpoint skips already-completed waypoints")
    func resumeFromCheckpoint() {
        var service = TourService()
        let tour = makeTwoWaypointTour()

        service.startTour(tour: tour, checkpoint: 1)

        #expect(service.tourStatus == .inProgress)
        #expect(service.completedWaypointIDs == ["wp1"])
        #expect(service.audioState.isAmbientPlaying == true)
        #expect(service.phase == .waitingForWaypoint)
    }
}
