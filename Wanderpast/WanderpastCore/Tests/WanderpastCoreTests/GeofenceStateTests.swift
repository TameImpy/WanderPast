import Testing
@testable import WanderpastCore

@Suite("GeofenceState")
struct GeofenceStateTests {

    // MARK: - 1. Start tour

    @Test("Starting a tour registers waypoints and switches accuracy to best")
    func startTourRegistersWaypoints() {
        var state = GeofenceState()
        let waypoints = [
            WaypointRegion(id: "wp1", latitude: 51.5074, longitude: -0.1278, radius: 20),
            WaypointRegion(id: "wp2", latitude: 51.5080, longitude: -0.1280, radius: 25),
        ]

        state.startTour(waypoints: waypoints)

        #expect(state.isTourActive == true)
        #expect(state.activeWaypointIDs == ["wp1", "wp2"])
        #expect(state.currentAccuracy == .best)
        #expect(state.triggeredWaypointID == nil)
    }

    // MARK: - 2. Region entry

    @Test("Entering a waypoint region sets triggeredWaypointID")
    func regionEntryTriggersWaypoint() {
        var state = GeofenceState()
        state.startTour(waypoints: [
            WaypointRegion(id: "wp1", latitude: 51.5074, longitude: -0.1278, radius: 20),
            WaypointRegion(id: "wp2", latitude: 51.5080, longitude: -0.1280, radius: 25),
        ])

        state.didEnterRegion(id: "wp1")

        #expect(state.triggeredWaypointID == "wp1")
    }

    // MARK: - 3. Jitter suppression

    @Test("Same waypoint does not re-trigger after initial entry")
    func jitterSuppression() {
        var state = GeofenceState()
        state.startTour(waypoints: [
            WaypointRegion(id: "wp1", latitude: 51.5074, longitude: -0.1278, radius: 20),
            WaypointRegion(id: "wp2", latitude: 51.5080, longitude: -0.1280, radius: 25),
        ])

        state.didEnterRegion(id: "wp1")
        #expect(state.triggeredWaypointID == "wp1")

        // Clear the trigger (simulating the manager consuming it)
        state.consumeTrigger()

        // Enter same region again — should not re-trigger
        state.didEnterRegion(id: "wp1")
        #expect(state.triggeredWaypointID == nil)
    }

    // MARK: - 4. Different waypoint triggers

    @Test("Entering a different waypoint triggers normally")
    func differentWaypointTriggers() {
        var state = GeofenceState()
        state.startTour(waypoints: [
            WaypointRegion(id: "wp1", latitude: 51.5074, longitude: -0.1278, radius: 20),
            WaypointRegion(id: "wp2", latitude: 51.5080, longitude: -0.1280, radius: 25),
        ])

        state.didEnterRegion(id: "wp1")
        state.consumeTrigger()

        state.didEnterRegion(id: "wp2")
        #expect(state.triggeredWaypointID == "wp2")
    }

    // MARK: - 5. Manual advance

    @Test("Manual advance triggers the next waypoint in sequence")
    func manualAdvance() {
        var state = GeofenceState()
        state.startTour(waypoints: [
            WaypointRegion(id: "wp1", latitude: 51.5074, longitude: -0.1278, radius: 20),
            WaypointRegion(id: "wp2", latitude: 51.5080, longitude: -0.1280, radius: 25),
            WaypointRegion(id: "wp3", latitude: 51.5085, longitude: -0.1282, radius: 20),
        ])

        state.didEnterRegion(id: "wp1")
        state.consumeTrigger()

        state.manualAdvance()

        #expect(state.triggeredWaypointID == "wp2")
    }

    // MARK: - 6. Manual advance bounds

    @Test("Manual advance on last waypoint is a no-op")
    func manualAdvanceAtEnd() {
        var state = GeofenceState()
        state.startTour(waypoints: [
            WaypointRegion(id: "wp1", latitude: 51.5074, longitude: -0.1278, radius: 20),
            WaypointRegion(id: "wp2", latitude: 51.5080, longitude: -0.1280, radius: 25),
        ])

        state.didEnterRegion(id: "wp1")
        state.consumeTrigger()
        state.manualAdvance()  // triggers wp2
        state.consumeTrigger()

        state.manualAdvance()  // should be no-op — wp2 is last

        #expect(state.triggeredWaypointID == nil)
    }

    // MARK: - 7. End tour

    @Test("Ending a tour clears waypoints and returns accuracy to reduced")
    func endTour() {
        var state = GeofenceState()
        state.startTour(waypoints: [
            WaypointRegion(id: "wp1", latitude: 51.5074, longitude: -0.1278, radius: 20),
        ])
        state.didEnterRegion(id: "wp1")

        state.endTour()

        #expect(state.isTourActive == false)
        #expect(state.activeWaypointIDs.isEmpty)
        #expect(state.currentAccuracy == .reduced)
        #expect(state.triggeredWaypointID == nil)
    }

    // MARK: - 8. New tour resets jitter

    @Test("Starting a new tour allows previously-triggered waypoints to trigger again")
    func newTourResetsJitter() {
        var state = GeofenceState()
        let waypoints = [
            WaypointRegion(id: "wp1", latitude: 51.5074, longitude: -0.1278, radius: 20),
        ]

        state.startTour(waypoints: waypoints)
        state.didEnterRegion(id: "wp1")
        state.endTour()

        // Start same tour again
        state.startTour(waypoints: waypoints)
        state.didEnterRegion(id: "wp1")

        #expect(state.triggeredWaypointID == "wp1")
    }
}
