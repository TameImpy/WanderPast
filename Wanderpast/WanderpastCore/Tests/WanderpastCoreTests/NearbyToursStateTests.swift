import Testing
import Foundation
@testable import WanderpastCore

@Suite("NearbyToursState mapping")
struct NearbyToursStateTests {

    @Test("granted + location + fresh catalogue → .loaded with nearby tours")
    func tracerBulletGrantedAndFresh() {
        let london = makeCity(id: "london")
        let tower = makeTour(id: "tower", cityID: "london")
        let start = makeWaypoint(id: "tower-w", tourID: "tower", latitude: 51.5081, longitude: -0.0759)
        let catalogue = Catalogue(cities: [london], tours: [tower], waypoints: [start])

        let state = NearbyToursState.from(
            authorization: .granted,
            userLocation: Coordinate(latitude: 51.5081, longitude: -0.0759),
            loadResult: .fresh(catalogue),
            radiusMeters: nil
        )

        if case .loaded(let nearby) = state {
            #expect(nearby.map { $0.tour.id } == ["tower"])
        } else {
            Issue.record("expected .loaded, got \(state)")
        }
    }

    @Test("notDetermined / denied / restricted authorization all become .hidden")
    func unauthorizedAuthorizationsAreHidden() {
        let catalogue = Catalogue(cities: [], tours: [], waypoints: [])
        let userLocation = Coordinate(latitude: 51.5081, longitude: -0.0759)

        for authorization in [LocationAuthorization.notDetermined, .denied, .restricted] {
            let state = NearbyToursState.from(
                authorization: authorization,
                userLocation: userLocation,
                loadResult: .fresh(catalogue),
                radiusMeters: nil
            )
            #expect(state == .hidden, "expected .hidden for \(authorization), got \(state)")
        }
    }

    @Test("granted but missing user location → .locating")
    func grantedWithoutLocationIsLocating() {
        let catalogue = Catalogue(cities: [], tours: [], waypoints: [])

        let state = NearbyToursState.from(
            authorization: .granted,
            userLocation: nil,
            loadResult: .fresh(catalogue),
            radiusMeters: nil
        )

        #expect(state == .locating)
    }

    @Test("granted with location but no catalogue yet → .locating")
    func grantedWithoutLoadResultIsLocating() {
        let state = NearbyToursState.from(
            authorization: .granted,
            userLocation: Coordinate(latitude: 51.5081, longitude: -0.0759),
            loadResult: nil,
            radiusMeters: nil
        )

        #expect(state == .locating)
    }

    @Test(".cached(catalogue, _) becomes .loaded regardless of isStale")
    func cachedBecomesLoaded() {
        let london = makeCity(id: "london")
        let tour = makeTour(id: "tower", cityID: "london")
        let start = makeWaypoint(id: "tower-w", tourID: "tower", latitude: 51.5081, longitude: -0.0759)
        let catalogue = Catalogue(cities: [london], tours: [tour], waypoints: [start])
        let userLocation = Coordinate(latitude: 51.5081, longitude: -0.0759)

        for isStale in [true, false] {
            let state = NearbyToursState.from(
                authorization: .granted,
                userLocation: userLocation,
                loadResult: .cached(catalogue, isStale: isStale),
                radiusMeters: nil
            )
            if case .loaded(let nearby) = state {
                #expect(nearby.map { $0.tour.id } == ["tower"])
            } else {
                Issue.record("expected .loaded for isStale=\(isStale), got \(state)")
            }
        }
    }

    @Test(".failure(.offline) and .failure(.fetchFailed) become .error(retryable: true)")
    func offlineAndFetchFailureAreRetryable() {
        let userLocation = Coordinate(latitude: 51.5081, longitude: -0.0759)

        let offline = NearbyToursState.from(
            authorization: .granted,
            userLocation: userLocation,
            loadResult: .failure(.offline),
            radiusMeters: nil
        )
        let fetchFailed = NearbyToursState.from(
            authorization: .granted,
            userLocation: userLocation,
            loadResult: .failure(.fetchFailed(.timeout)),
            radiusMeters: nil
        )

        #expect(offline == .error(retryable: true))
        #expect(fetchFailed == .error(retryable: true))
    }

    @Test(".failure(.parseFailed) becomes .error(retryable: false)")
    func parseFailureIsNotRetryable() {
        let state = NearbyToursState.from(
            authorization: .granted,
            userLocation: Coordinate(latitude: 51.5081, longitude: -0.0759),
            loadResult: .failure(.parseFailed(.malformed)),
            radiusMeters: nil
        )

        #expect(state == .error(retryable: false))
    }

    @Test("radiusMeters caps the surfaced tours — tours beyond the cap are excluded")
    func radiusCapFiltersResults() {
        let london = makeCity(id: "london")
        let near = makeTour(id: "near", cityID: "london")
        let far = makeTour(id: "far", cityID: "london")
        let waypoints = [
            makeWaypoint(id: "near-w", tourID: "near", latitude: 51.5085, longitude: -0.0759),
            makeWaypoint(id: "far-w", tourID: "far", latitude: 51.55, longitude: -0.0759),
        ]
        let catalogue = Catalogue(cities: [london], tours: [near, far], waypoints: waypoints)

        let state = NearbyToursState.from(
            authorization: .granted,
            userLocation: Coordinate(latitude: 51.5081, longitude: -0.0759),
            loadResult: .fresh(catalogue),
            radiusMeters: 500
        )

        if case .loaded(let nearby) = state {
            #expect(nearby.map { $0.tour.id } == ["near"])
        } else {
            Issue.record("expected .loaded, got \(state)")
        }
    }
}

// MARK: - Fixtures

private func makeCity(id: String) -> City {
    City(
        id: id,
        name: id.capitalized,
        description: "",
        heroImageURL: nil,
        tourCount: 1,
        editorialPickTourID: nil,
        generalAccessibilityNote: nil
    )
}

private func makeTour(id: String, cityID: String) -> Tour {
    Tour(
        id: id,
        title: id,
        city: cityID,
        theme: "",
        era: "Medieval",
        eraStartYear: 1100,
        narrationStyle: .presentTenseOmniscient,
        narratorName: "",
        narratorBio: "",
        durationMinutes: 0,
        waypointCount: 0,
        description: "",
        previewClipURL: nil,
        ambientSoundscapeURL: nil,
        completionSummary: "",
        heroImageURL: nil,
        isFree: true,
        priceTier: .free,
        status: .published
    )
}

private func makeWaypoint(
    id: String,
    tourID: String,
    latitude: Double,
    longitude: Double
) -> Waypoint {
    Waypoint(
        id: id,
        tourID: tourID,
        order: 1,
        title: id,
        latitude: latitude,
        longitude: longitude,
        triggerRadiusM: 30,
        audioURL: URL(string: "https://example.com/a.mp3")!,
        transitionAudioURL: nil
    )
}
