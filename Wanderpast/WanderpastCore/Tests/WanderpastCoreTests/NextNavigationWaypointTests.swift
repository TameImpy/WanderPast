import Testing
@testable import WanderpastCore

@Suite("TourService.nextNavigationWaypointID")
struct NextNavigationWaypointTests {

    private func makeThreeWaypointTour() -> TourManifest {
        TourManifest(waypoints: [
            TourManifest.Waypoint(id: "wp1", latitude: 51.50, longitude: -0.10, radius: 20),
            TourManifest.Waypoint(id: "wp2", latitude: 51.51, longitude: -0.11, radius: 20),
            TourManifest.Waypoint(id: "wp3", latitude: 51.52, longitude: -0.12, radius: 20),
        ])
    }

    @Test("Before a tour starts, there is no next-navigation waypoint")
    func notStarted() {
        let service = TourService()

        #expect(service.nextNavigationWaypointID == nil)
    }

    @Test("Right after starting, the next destination is the first waypoint")
    func waitingForFirstWaypoint() {
        var service = TourService()
        service.startTour(tour: makeThreeWaypointTour())

        #expect(service.nextNavigationWaypointID == "wp1")
    }

    @Test("While a waypoint is playing, the next destination skips it")
    func playingWaypointSkipsItself() {
        var service = TourService()
        service.startTour(tour: makeThreeWaypointTour())

        service.onWaypointEntered(id: "wp1")

        // User has physically reached wp1; "Help I'm lost" should point at wp2.
        #expect(service.nextNavigationWaypointID == "wp2")
    }

    @Test("Between waypoints, the next destination is the first uncompleted one")
    func betweenWaypoints() {
        var service = TourService()
        service.startTour(tour: makeThreeWaypointTour())

        service.onWaypointEntered(id: "wp1")
        service.onWaypointAudioFinished()    // playingTransition, wp1 completed

        #expect(service.nextNavigationWaypointID == "wp2")

        service.onTransitionAudioFinished()  // waitingForWaypoint
        #expect(service.nextNavigationWaypointID == "wp2")
    }

    @Test("Once the tour is completed, there is no next-navigation waypoint")
    func completed() {
        var service = TourService()
        service.startTour(tour: makeThreeWaypointTour())

        for id in ["wp1", "wp2", "wp3"] {
            service.onWaypointEntered(id: id)
            service.onWaypointAudioFinished()
            service.onTransitionAudioFinished()
        }

        #expect(service.nextNavigationWaypointID == nil)
    }
}
