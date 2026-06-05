import Testing
import Foundation
@testable import WanderpastCore

@Suite("ThemeBrowseState mapping")
struct ThemeBrowseStateTests {

    @Test("Loaded: groups published tours by era, ordered by eraStartYear")
    func loadedGroupsByEra() {
        let catalogue = makeMultiEraCatalogue()

        let state = ThemeBrowseState.from(loadResult: .fresh(catalogue))

        guard case .loaded(let groups) = state else {
            Issue.record("expected .loaded, got \(state)")
            return
        }
        #expect(groups.map(\.era) == ["Early Medieval (600–1100)", "Twentieth Century (1900–2000)"])
        #expect(groups.first?.tours.map(\.id) == ["jorvik"])
        #expect(groups.last?.tours.map(\.id) == ["blitz"])
    }

    @Test("Loaded: cached result is treated as loaded")
    func cachedIsLoaded() {
        let catalogue = makeMultiEraCatalogue()

        let state = ThemeBrowseState.from(loadResult: .cached(catalogue, isStale: false))

        guard case .loaded(let groups) = state else {
            Issue.record("expected .loaded, got \(state)")
            return
        }
        #expect(groups.count == 2)
    }

    @Test(".failure(.offline) becomes .error(retryable: true)")
    func offlineRetryable() {
        let state = ThemeBrowseState.from(loadResult: .failure(.offline))
        #expect(state == .error(retryable: true))
    }

    @Test(".failure(.fetchFailed) becomes .error(retryable: true)")
    func fetchFailedRetryable() {
        let state = ThemeBrowseState.from(loadResult: .failure(.fetchFailed(.notFound)))
        #expect(state == .error(retryable: true))
    }

    @Test(".failure(.parseFailed) becomes .error(retryable: false)")
    func parseFailedNotRetryable() {
        let state = ThemeBrowseState.from(loadResult: .failure(.parseFailed(.empty)))
        #expect(state == .error(retryable: false))
    }
}

// MARK: - Fixtures

private func makeMultiEraCatalogue() -> Catalogue {
    let london = City(
        id: "london", name: "London", description: "",
        heroImageURL: nil, tourCount: 0,
        editorialPickTourID: nil, generalAccessibilityNote: nil
    )
    let blitz = makeTour(id: "blitz", city: "london", era: "Twentieth Century (1900–2000)", year: 1940)
    let jorvik = makeTour(id: "jorvik", city: "london", era: "Early Medieval (600–1100)", year: 866)
    return Catalogue(cities: [london], tours: [blitz, jorvik], waypoints: [])
}

private func makeTour(id: String, city: String, era: String, year: Int) -> Tour {
    Tour(
        id: id, title: id, city: city, theme: "",
        era: era, eraStartYear: year,
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
