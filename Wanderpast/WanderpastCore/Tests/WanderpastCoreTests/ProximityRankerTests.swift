import Testing
import Foundation
@testable import WanderpastCore

@Suite("Proximity ranker")
struct ProximityRankerTests {

    @Test("nearbyTours returns one entry per published tour with a starting waypoint")
    func tracerBulletSingleTour() {
        let london = makeCity(id: "london")
        let tower = makeTour(id: "tower", cityID: "london", status: .published)
        let start = makeWaypoint(id: "w1", tourID: "tower", order: 1, latitude: 51.5081, longitude: -0.0759)
        let catalogue = Catalogue(cities: [london], tours: [tower], waypoints: [start])

        let origin = Coordinate(latitude: 51.5081, longitude: -0.0759)

        let result = catalogue.nearbyTours(from: origin, within: nil)

        #expect(result.map { $0.tour.id } == ["tower"])
        #expect(result.first?.distanceMeters ?? .infinity < 1)
        #expect(result.first?.startCoordinate == Coordinate(latitude: 51.5081, longitude: -0.0759))
    }

    @Test("nearbyTours sorts results ascending by distance to the starting waypoint")
    func sortsByAscendingDistance() {
        let london = makeCity(id: "london")
        let near = makeTour(id: "near", cityID: "london", status: .published)
        let mid = makeTour(id: "mid", cityID: "london", status: .published)
        let far = makeTour(id: "far", cityID: "london", status: .published)
        let waypoints = [
            makeWaypoint(id: "far-w", tourID: "far", order: 1, latitude: 51.55, longitude: -0.0759),
            makeWaypoint(id: "near-w", tourID: "near", order: 1, latitude: 51.5085, longitude: -0.0759),
            makeWaypoint(id: "mid-w", tourID: "mid", order: 1, latitude: 51.52, longitude: -0.0759),
        ]
        let catalogue = Catalogue(cities: [london], tours: [far, near, mid], waypoints: waypoints)

        let origin = Coordinate(latitude: 51.5081, longitude: -0.0759)

        let result = catalogue.nearbyTours(from: origin, within: nil)

        #expect(result.map { $0.tour.id } == ["near", "mid", "far"])
    }

    @Test("nearbyTours excludes draft and archived tours")
    func excludesNonPublishedTours() {
        let london = makeCity(id: "london")
        let published = makeTour(id: "live", cityID: "london", status: .published)
        let draft = makeTour(id: "draft", cityID: "london", status: .draft)
        let archived = makeTour(id: "archived", cityID: "london", status: .archived)
        let waypoints = [
            makeWaypoint(id: "live-w", tourID: "live", order: 1, latitude: 51.5081, longitude: -0.0759),
            makeWaypoint(id: "draft-w", tourID: "draft", order: 1, latitude: 51.5081, longitude: -0.0759),
            makeWaypoint(id: "archived-w", tourID: "archived", order: 1, latitude: 51.5081, longitude: -0.0759),
        ]
        let catalogue = Catalogue(
            cities: [london],
            tours: [published, draft, archived],
            waypoints: waypoints
        )

        let result = catalogue.nearbyTours(
            from: Coordinate(latitude: 51.5081, longitude: -0.0759),
            within: nil
        )

        #expect(result.map { $0.tour.id } == ["live"])
    }

    @Test("nearbyTours excludes published tours that have no waypoints")
    func excludesPublishedTourWithoutWaypoints() {
        let london = makeCity(id: "london")
        let hasWaypoints = makeTour(id: "real", cityID: "london", status: .published)
        let empty = makeTour(id: "empty", cityID: "london", status: .published)
        let waypoint = makeWaypoint(id: "real-w", tourID: "real", order: 1, latitude: 51.5081, longitude: -0.0759)
        let catalogue = Catalogue(
            cities: [london],
            tours: [hasWaypoints, empty],
            waypoints: [waypoint]
        )

        let result = catalogue.nearbyTours(
            from: Coordinate(latitude: 51.5081, longitude: -0.0759),
            within: nil
        )

        #expect(result.map { $0.tour.id } == ["real"])
    }

    @Test("nearbyTours measures distance from the waypoint with the lowest order, not array position")
    func measuresFromLowestOrderWaypoint() {
        let london = makeCity(id: "london")
        let tour = makeTour(id: "tower", cityID: "london", status: .published)
        // Last in array but order=1 → this is the true start.
        let trueStart = makeWaypoint(id: "start", tourID: "tower", order: 1, latitude: 51.5081, longitude: -0.0759)
        let secondStop = makeWaypoint(id: "stop", tourID: "tower", order: 2, latitude: 51.55, longitude: -0.0759)
        let catalogue = Catalogue(
            cities: [london],
            tours: [tour],
            waypoints: [secondStop, trueStart]
        )

        let result = catalogue.nearbyTours(
            from: Coordinate(latitude: 51.5081, longitude: -0.0759),
            within: nil
        )

        #expect(result.first?.startCoordinate == Coordinate(latitude: 51.5081, longitude: -0.0759))
        #expect((result.first?.distanceMeters ?? .infinity) < 1)
    }

    @Test("nearbyTours within: maxMeters excludes tours beyond the cap")
    func radiusCapExcludesDistantTours() {
        let london = makeCity(id: "london")
        let close = makeTour(id: "close", cityID: "london", status: .published)
        let distant = makeTour(id: "distant", cityID: "london", status: .published)
        let waypoints = [
            // ~44 m north of origin.
            makeWaypoint(id: "close-w", tourID: "close", order: 1, latitude: 51.5085, longitude: -0.0759),
            // ~4.6 km north of origin.
            makeWaypoint(id: "distant-w", tourID: "distant", order: 1, latitude: 51.55, longitude: -0.0759),
        ]
        let catalogue = Catalogue(
            cities: [london],
            tours: [close, distant],
            waypoints: waypoints
        )

        let result = catalogue.nearbyTours(
            from: Coordinate(latitude: 51.5081, longitude: -0.0759),
            within: 500
        )

        #expect(result.map { $0.tour.id } == ["close"])
    }

    @Test("nearbyTours reports a sensible distance for a known city pair (London → York ≈ 280 km)")
    func distanceMatchesKnownCityPair() {
        let london = makeCity(id: "london")
        let yorkTour = makeTour(id: "york-tour", cityID: "london", status: .published)
        let yorkStart = makeWaypoint(id: "york-w", tourID: "york-tour", order: 1, latitude: 53.9590, longitude: -1.0815)
        let catalogue = Catalogue(cities: [london], tours: [yorkTour], waypoints: [yorkStart])

        // London (Tower of London).
        let origin = Coordinate(latitude: 51.5081, longitude: -0.0759)

        let result = catalogue.nearbyTours(from: origin, within: nil)

        let distance = result.first?.distanceMeters ?? .infinity
        #expect(distance > 270_000 && distance < 290_000)
    }
}

// MARK: - Fixture builders

private func makeCity(
    id: String,
    editorialPickTourID: String? = nil
) -> City {
    City(
        id: id,
        name: id.capitalized,
        description: "desc",
        heroImageURL: nil,
        tourCount: 1,
        editorialPickTourID: editorialPickTourID,
        generalAccessibilityNote: nil
    )
}

private func makeTour(
    id: String,
    cityID: String,
    status: TourContentStatus
) -> Tour {
    Tour(
        id: id,
        title: id,
        city: cityID,
        theme: "theme",
        era: "Medieval",
        eraStartYear: 1100,
        narrationStyle: .presentTenseOmniscient,
        narratorName: "n",
        narratorBio: "b",
        durationMinutes: 30,
        waypointCount: 0,
        description: "d",
        previewClipURL: nil,
        ambientSoundscapeURL: nil,
        completionSummary: "c",
        heroImageURL: nil,
        isFree: true,
        priceTier: .free,
        status: status
    )
}

private func makeWaypoint(
    id: String,
    tourID: String,
    order: Int,
    latitude: Double = 0,
    longitude: Double = 0
) -> Waypoint {
    Waypoint(
        id: id,
        tourID: tourID,
        order: order,
        title: id,
        latitude: latitude,
        longitude: longitude,
        triggerRadiusM: 30,
        audioURL: URL(string: "https://example.com/a.mp3")!,
        transitionAudioURL: nil
    )
}
