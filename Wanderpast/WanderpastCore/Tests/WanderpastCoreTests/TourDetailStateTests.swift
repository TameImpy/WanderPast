import Testing
import Foundation
@testable import WanderpastCore

@Suite("TourDetailState mapping")
struct TourDetailStateTests {

    @Test("Fresh load with matching tourID becomes .loaded with the tour and its sorted waypoints")
    func freshMatchingTourIsLoaded() {
        let catalogue = makeCatalogue(
            tours: [("tour-a", "city-a"), ("tour-b", "city-a")],
            waypointsByTour: ["tour-a": [3, 1, 2]]
        )

        let state = TourDetailState.from(loadResult: .fresh(catalogue), tourID: "tour-a")

        guard case .loaded(let tour, let waypoints) = state else {
            Issue.record("expected .loaded, got \(state)")
            return
        }
        #expect(tour.id == "tour-a")
        #expect(waypoints.map(\.order) == [1, 2, 3])
    }

    @Test("Cached load with matching tourID becomes .loaded regardless of staleness")
    func cachedMatchingTourIsLoaded() {
        let catalogue = makeCatalogue(
            tours: [("tour-a", "city-a")],
            waypointsByTour: ["tour-a": [1]]
        )

        let state = TourDetailState.from(loadResult: .cached(catalogue, isStale: true), tourID: "tour-a")

        guard case .loaded(let tour, let waypoints) = state else {
            Issue.record("expected .loaded, got \(state)")
            return
        }
        #expect(tour.id == "tour-a")
        #expect(waypoints.count == 1)
    }

    @Test("Catalogue parses but tourID is absent becomes .notFound")
    func unknownTourIsNotFound() {
        let catalogue = makeCatalogue(
            tours: [("tour-a", "city-a")],
            waypointsByTour: ["tour-a": [1]]
        )

        let state = TourDetailState.from(loadResult: .fresh(catalogue), tourID: "ghost-tour")

        #expect(state == .notFound)
    }

    @Test(".failure(.offline) becomes .error(retryable: true)")
    func offlineRetryable() {
        let state = TourDetailState.from(loadResult: .failure(.offline), tourID: "tour-a")
        #expect(state == .error(retryable: true))
    }

    @Test(".failure(.fetchFailed) becomes .error(retryable: true)")
    func fetchFailedRetryable() {
        let state = TourDetailState.from(loadResult: .failure(.fetchFailed(.timeout)), tourID: "tour-a")
        #expect(state == .error(retryable: true))
    }

    @Test(".failure(.parseFailed) becomes .error(retryable: false)")
    func parseFailedNotRetryable() {
        let state = TourDetailState.from(loadResult: .failure(.parseFailed(.malformed)), tourID: "tour-a")
        #expect(state == .error(retryable: false))
    }
}

// MARK: - Fixtures

private func makeCatalogue(
    tours: [(String, String)],
    waypointsByTour: [String: [Int]]
) -> Catalogue {
    let cityIDs = Set(tours.map { $0.1 })
    let cities = cityIDs.map {
        City(
            id: $0, name: $0.capitalized, description: "",
            heroImageURL: nil, tourCount: 0,
            editorialPickTourID: nil, generalAccessibilityNote: nil
        )
    }
    let tourModels = tours.map { id, city in
        Tour(
            id: id, title: id, city: city, theme: "",
            era: "Medieval", eraStartYear: 1100,
            narrationStyle: .presentTenseOmniscient,
            narratorName: "", narratorBio: "",
            durationMinutes: 0, waypointCount: 0,
            description: "",
            previewClipURL: nil, ambientSoundscapeURL: nil,
            completionSummary: "", heroImageURL: nil,
            isFree: true, priceTier: .free,
            status: .published
        )
    }
    var waypoints: [Waypoint] = []
    for (tourID, orders) in waypointsByTour {
        for order in orders {
            waypoints.append(
                Waypoint(
                    id: "\(tourID)-wp\(order)",
                    tourID: tourID,
                    order: order,
                    title: "WP \(order)",
                    latitude: 51.5,
                    longitude: -0.1,
                    triggerRadiusM: 25,
                    audioURL: URL(string: "https://example.com/\(tourID)-\(order).mp3")!,
                    transitionAudioURL: nil
                )
            )
        }
    }
    return Catalogue(cities: cities, tours: tourModels, waypoints: waypoints)
}
