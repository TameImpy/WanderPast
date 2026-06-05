import Testing
import Foundation
@testable import WanderpastCore

@Suite("TourListState mapping")
struct TourListStateTests {

    @Test("Loaded: editorial pick is excluded from others")
    func editorialPickExcludedFromOthers() {
        let catalogue = makeCatalogue(
            cities: [("london", editorialPickID: "london-1")],
            tours: ["london-1", "london-2", "london-3"].map { ($0, "london") }
        )

        let state = TourListState.from(loadResult: .fresh(catalogue), cityID: "london")

        guard case .loaded(let pick, let others) = state else {
            Issue.record("expected .loaded, got \(state)")
            return
        }
        #expect(pick?.id == "london-1")
        #expect(others.map(\.id) == ["london-2", "london-3"])
    }

    @Test("Loaded: city with no editorial pick puts every tour in others")
    func noPickEverythingInOthers() {
        let catalogue = makeCatalogue(
            cities: [("york", editorialPickID: nil)],
            tours: ["york-1", "york-2"].map { ($0, "york") }
        )

        let state = TourListState.from(loadResult: .fresh(catalogue), cityID: "york")

        guard case .loaded(let pick, let others) = state else {
            Issue.record("expected .loaded, got \(state)")
            return
        }
        #expect(pick == nil)
        #expect(others.map(\.id) == ["york-1", "york-2"])
    }

    @Test("Loaded: cached result maps the same as fresh")
    func cachedMapsLikeFresh() {
        let catalogue = makeCatalogue(
            cities: [("london", editorialPickID: "london-1")],
            tours: ["london-1", "london-2"].map { ($0, "london") }
        )

        let state = TourListState.from(loadResult: .cached(catalogue, isStale: true), cityID: "london")

        guard case .loaded(let pick, let others) = state else {
            Issue.record("expected .loaded, got \(state)")
            return
        }
        #expect(pick?.id == "london-1")
        #expect(others.map(\.id) == ["london-2"])
    }

    @Test("Loaded: unknown cityID yields empty result rather than an error")
    func unknownCityIsEmptyLoaded() {
        let catalogue = makeCatalogue(
            cities: [("london", editorialPickID: nil)],
            tours: ["london-1"].map { ($0, "london") }
        )

        let state = TourListState.from(loadResult: .fresh(catalogue), cityID: "bath")

        guard case .loaded(let pick, let others) = state else {
            Issue.record("expected .loaded, got \(state)")
            return
        }
        #expect(pick == nil)
        #expect(others.isEmpty)
    }

    @Test(".failure(.offline) becomes .error(retryable: true)")
    func offlineRetryable() {
        let state = TourListState.from(loadResult: .failure(.offline), cityID: "london")
        #expect(state == .error(retryable: true))
    }

    @Test(".failure(.fetchFailed) becomes .error(retryable: true)")
    func fetchFailedRetryable() {
        let state = TourListState.from(loadResult: .failure(.fetchFailed(.timeout)), cityID: "london")
        #expect(state == .error(retryable: true))
    }

    @Test(".failure(.parseFailed) becomes .error(retryable: false)")
    func parseFailedNotRetryable() {
        let state = TourListState.from(loadResult: .failure(.parseFailed(.malformed)), cityID: "london")
        #expect(state == .error(retryable: false))
    }
}

// MARK: - Fixtures

private func makeCatalogue(
    cities: [(String, editorialPickID: String?)],
    tours: [(String, String)]
) -> Catalogue {
    let cityModels = cities.map { id, pickID in
        City(
            id: id,
            name: id.capitalized,
            description: "",
            heroImageURL: nil,
            tourCount: 0,
            editorialPickTourID: pickID,
            generalAccessibilityNote: nil
        )
    }
    let tourModels = tours.map { id, cityID in
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
    return Catalogue(cities: cityModels, tours: tourModels, waypoints: [])
}
