import Testing
@testable import WanderpastCore

@Suite("TourProgress")
struct TourProgressTests {

    private func makeThreeWaypointTour() -> TourManifest {
        TourManifest(waypoints: [
            TourManifest.Waypoint(id: "wp1", latitude: 51.50, longitude: -0.10, radius: 20),
            TourManifest.Waypoint(id: "wp2", latitude: 51.51, longitude: -0.11, radius: 20),
            TourManifest.Waypoint(id: "wp3", latitude: 51.52, longitude: -0.12, radius: 20),
        ])
    }

    @Test("Before a tour starts, progress is 0 of 0")
    func notStarted() {
        let service = TourService()

        #expect(service.progress.currentStopNumber == 0)
        #expect(service.progress.totalStops == 0)
    }

    @Test("Right after starting, the user is walking toward stop 1 of 3")
    func startedButNoWaypointEntered() {
        var service = TourService()
        service.startTour(tour: makeThreeWaypointTour())

        #expect(service.progress.currentStopNumber == 1)
        #expect(service.progress.totalStops == 3)
    }

    @Test("While a waypoint is playing, progress is the index of that waypoint")
    func playingWaypoint() {
        var service = TourService()
        service.startTour(tour: makeThreeWaypointTour())

        service.onWaypointEntered(id: "wp1")
        #expect(service.progress.currentStopNumber == 1)

        service.onWaypointAudioFinished()    // wp1 completed, walking to wp2
        #expect(service.progress.currentStopNumber == 2)

        service.onTransitionAudioFinished()  // still waiting for wp2
        service.onWaypointEntered(id: "wp2")
        #expect(service.progress.currentStopNumber == 2)
    }

    @Test("Once the tour is completed, progress shows the final stop")
    func completed() {
        var service = TourService()
        service.startTour(tour: makeThreeWaypointTour())

        for id in ["wp1", "wp2", "wp3"] {
            service.onWaypointEntered(id: id)
            service.onWaypointAudioFinished()
            service.onTransitionAudioFinished()
        }

        #expect(service.tourStatus == .completed)
        #expect(service.progress.currentStopNumber == 3)
        #expect(service.progress.totalStops == 3)
    }
}
