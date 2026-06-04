import Testing
import Foundation
@testable import WanderpastCore

@Suite("CityBrowseState mapping")
struct CityBrowseStateTests {

    @Test(".fresh(catalogue) becomes .loaded with the catalogue's city rows")
    func freshBecomesLoaded() {
        let catalogue = makeCatalogue(cityIDs: ["london"], publishedToursPerCity: 1)

        let state = CityBrowseState.from(loadResult: .fresh(catalogue))

        if case .loaded(let rows) = state {
            #expect(rows.map(\.id) == ["london"])
        } else {
            Issue.record("expected .loaded, got \(state)")
        }
    }

    @Test(".cached(catalogue, _) becomes .loaded regardless of isStale")
    func cachedBecomesLoaded() {
        let catalogue = makeCatalogue(cityIDs: ["york"], publishedToursPerCity: 1)

        let staleState = CityBrowseState.from(loadResult: .cached(catalogue, isStale: true))
        let freshCachedState = CityBrowseState.from(loadResult: .cached(catalogue, isStale: false))

        for state in [staleState, freshCachedState] {
            if case .loaded(let rows) = state {
                #expect(rows.map(\.id) == ["york"])
            } else {
                Issue.record("expected .loaded, got \(state)")
            }
        }
    }

    @Test(".failure(.offline) becomes .error(retryable: true)")
    func offlineIsRetryable() {
        let state = CityBrowseState.from(loadResult: .failure(.offline))

        #expect(state == .error(retryable: true))
    }

    @Test(".failure(.fetchFailed) becomes .error(retryable: true)")
    func fetchFailureIsRetryable() {
        let state = CityBrowseState.from(loadResult: .failure(.fetchFailed(.timeout)))

        #expect(state == .error(retryable: true))
    }

    @Test(".failure(.parseFailed) becomes .error(retryable: false)")
    func parseFailureIsNotRetryable() {
        let state = CityBrowseState.from(loadResult: .failure(.parseFailed(.malformed)))

        #expect(state == .error(retryable: false))
    }
}

// MARK: - Fixtures

private func makeCatalogue(cityIDs: [String], publishedToursPerCity: Int) -> Catalogue {
    let cities = cityIDs.map {
        City(
            id: $0,
            name: $0.capitalized,
            description: "",
            heroImageURL: nil,
            tourCount: publishedToursPerCity,
            editorialPickTourID: nil,
            generalAccessibilityNote: nil
        )
    }
    var tours: [Tour] = []
    for cityID in cityIDs {
        for index in 0..<publishedToursPerCity {
            tours.append(
                Tour(
                    id: "\(cityID)-\(index)",
                    title: "T",
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
            )
        }
    }
    return Catalogue(cities: cities, tours: tours, waypoints: [])
}
