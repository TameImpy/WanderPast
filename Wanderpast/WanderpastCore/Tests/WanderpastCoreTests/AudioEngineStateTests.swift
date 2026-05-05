import Testing
@testable import WanderpastCore

@Suite("AudioEngineState")
struct AudioEngineStateTests {

    // MARK: - 1. Start tour

    @Test("Starting a tour plays ambient at full volume with no waypoint")
    func startTourPlaysAmbient() {
        var engine = AudioEngineState()
        let waypoints = ["wp1", "wp2", "wp3"]

        engine.startTour(waypoints: waypoints)

        #expect(engine.isAmbientPlaying == true)
        #expect(engine.ambientVolume == 1.0)
        #expect(engine.isWaypointPlaying == false)
        #expect(engine.currentWaypointID == nil)
        #expect(engine.isPaused == false)
    }

    // MARK: - 2. Trigger waypoint

    @Test("Triggering a waypoint dips ambient and plays waypoint audio")
    func triggerWaypointDipsAmbientAndPlays() {
        var engine = AudioEngineState()
        engine.startTour(waypoints: ["wp1", "wp2", "wp3"])

        engine.triggerWaypoint(id: "wp1")

        #expect(engine.isWaypointPlaying == true)
        #expect(engine.currentWaypointID == "wp1")
        #expect(engine.ambientVolume < 1.0)
        #expect(engine.isAmbientPlaying == true)
    }

    // MARK: - 3. Waypoint finishes

    @Test("When waypoint finishes playing, ambient returns to full volume")
    func waypointFinishesRestoresAmbient() {
        var engine = AudioEngineState()
        engine.startTour(waypoints: ["wp1", "wp2", "wp3"])
        engine.triggerWaypoint(id: "wp1")

        engine.waypointDidFinishPlaying()

        #expect(engine.isWaypointPlaying == false)
        #expect(engine.currentWaypointID == nil)
        #expect(engine.ambientVolume == 1.0)
        #expect(engine.isAmbientPlaying == true)
    }

    // MARK: - 4. Pause/resume

    @Test("Pause stops both channels, resume restores them")
    func pauseAndResume() {
        var engine = AudioEngineState()
        engine.startTour(waypoints: ["wp1", "wp2", "wp3"])
        engine.triggerWaypoint(id: "wp1")

        engine.togglePause()

        #expect(engine.isPaused == true)
        #expect(engine.isAmbientPlaying == false)
        #expect(engine.isWaypointPlaying == false)

        engine.togglePause()

        #expect(engine.isPaused == false)
        #expect(engine.isAmbientPlaying == true)
        #expect(engine.isWaypointPlaying == true)
        #expect(engine.currentWaypointID == "wp1")
    }

    // MARK: - 5. Phone call interruption

    @Test("Phone call pauses playback, ending call resumes it")
    func phoneCallInterruption() {
        var engine = AudioEngineState()
        engine.startTour(waypoints: ["wp1", "wp2", "wp3"])
        engine.triggerWaypoint(id: "wp1")

        engine.handleInterruption(.began)

        #expect(engine.isPaused == true)
        #expect(engine.isAmbientPlaying == false)
        #expect(engine.isWaypointPlaying == false)

        engine.handleInterruption(.ended(shouldResume: true))

        #expect(engine.isPaused == false)
        #expect(engine.isAmbientPlaying == true)
        #expect(engine.isWaypointPlaying == true)
        #expect(engine.currentWaypointID == "wp1")
    }

    // MARK: - 6. Headphone disconnect

    @Test("Headphone disconnect pauses playback but does not auto-resume")
    func headphoneDisconnect() {
        var engine = AudioEngineState()
        engine.startTour(waypoints: ["wp1", "wp2", "wp3"])
        engine.triggerWaypoint(id: "wp1")

        engine.handleRouteChange(.headphonesUnplugged)

        #expect(engine.isPaused == true)
        #expect(engine.isAmbientPlaying == false)
        #expect(engine.isWaypointPlaying == false)
        // User must manually resume — no auto-resume after headphone disconnect
    }

    // MARK: - 7. Skip forward

    @Test("Skip forward stops current waypoint and plays the next one")
    func skipForward() {
        var engine = AudioEngineState()
        engine.startTour(waypoints: ["wp1", "wp2", "wp3"])
        engine.triggerWaypoint(id: "wp1")

        engine.skipForward()

        #expect(engine.isWaypointPlaying == true)
        #expect(engine.currentWaypointID == "wp2")
        #expect(engine.ambientVolume < 1.0)
    }

    // MARK: - 8. Skip backward

    @Test("Skip backward stops current waypoint and plays the previous one")
    func skipBackward() {
        var engine = AudioEngineState()
        engine.startTour(waypoints: ["wp1", "wp2", "wp3"])
        engine.triggerWaypoint(id: "wp2")

        engine.skipBackward()

        #expect(engine.isWaypointPlaying == true)
        #expect(engine.currentWaypointID == "wp1")
        #expect(engine.ambientVolume < 1.0)
    }

    // MARK: - 9. Skip bounds

    @Test("Skip forward on last waypoint is a no-op")
    func skipForwardAtEnd() {
        var engine = AudioEngineState()
        engine.startTour(waypoints: ["wp1", "wp2", "wp3"])
        engine.triggerWaypoint(id: "wp3")

        engine.skipForward()

        #expect(engine.currentWaypointID == "wp3")
        #expect(engine.isWaypointPlaying == true)
    }

    @Test("Skip backward on first waypoint is a no-op")
    func skipBackwardAtStart() {
        var engine = AudioEngineState()
        engine.startTour(waypoints: ["wp1", "wp2", "wp3"])
        engine.triggerWaypoint(id: "wp1")

        engine.skipBackward()

        #expect(engine.currentWaypointID == "wp1")
        #expect(engine.isWaypointPlaying == true)
    }
}
