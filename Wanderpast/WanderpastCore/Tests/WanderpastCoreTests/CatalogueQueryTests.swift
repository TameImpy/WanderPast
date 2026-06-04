import Testing
import Foundation
@testable import WanderpastCore

@Suite("Catalogue queries")
struct CatalogueQueryTests {

    @Test("publishedCities returns cities that have at least one published tour")
    func publishedCitiesIncludesCityWithPublishedTour() {
        let london = makeCity(id: "london")
        let tour = makeTour(id: "tower", cityID: "london", status: .published)
        let catalogue = Catalogue(cities: [london], tours: [tour], waypoints: [])

        let result = catalogue.publishedCities()

        #expect(result.map(\.id) == ["london"])
    }

    @Test("tours(in:) puts the city's editorial pick first")
    func toursInCityPutsEditorialPickFirst() {
        let london = makeCity(id: "london", editorialPickTourID: "raleigh")
        let bones = makeTour(id: "bones", cityID: "london", status: .published)
        let raleigh = makeTour(id: "raleigh", cityID: "london", status: .published)
        let plague = makeTour(id: "plague", cityID: "london", status: .published)
        let catalogue = Catalogue(
            cities: [london],
            tours: [bones, raleigh, plague],
            waypoints: []
        )

        let result = catalogue.tours(in: "london")

        #expect(result.first?.id == "raleigh")
        #expect(Set(result.map(\.id)) == ["bones", "raleigh", "plague"])
    }

    @Test("tours(in:) returns only published tours for that city")
    func toursInCityReturnsOnlyPublished() {
        let london = makeCity(id: "london")
        let york = makeCity(id: "york")
        let publishedInLondon = makeTour(id: "tower", cityID: "london", status: .published)
        let draftInLondon = makeTour(id: "tower-draft", cityID: "london", status: .draft)
        let publishedInYork = makeTour(id: "york-mystery", cityID: "york", status: .published)
        let catalogue = Catalogue(
            cities: [london, york],
            tours: [publishedInLondon, draftInLondon, publishedInYork],
            waypoints: []
        )

        let result = catalogue.tours(in: "london")

        #expect(result.map(\.id) == ["tower"])
    }

    @Test("tour(id:) returns the matching tour, or nil")
    func tourByIDLookup() {
        let london = makeCity(id: "london")
        let tower = makeTour(id: "tower", cityID: "london", status: .published)
        let catalogue = Catalogue(cities: [london], tours: [tower], waypoints: [])

        #expect(catalogue.tour(id: "tower")?.id == "tower")
        #expect(catalogue.tour(id: "ghost") == nil)
    }

    @Test("waypoints(for:) returns waypoints for that tour, sorted by order")
    func waypointsForTourSortedByOrder() {
        let third = makeWaypoint(id: "c", tourID: "tower", order: 3)
        let first = makeWaypoint(id: "a", tourID: "tower", order: 1)
        let second = makeWaypoint(id: "b", tourID: "tower", order: 2)
        let otherTour = makeWaypoint(id: "x", tourID: "york", order: 1)
        let catalogue = Catalogue(
            cities: [],
            tours: [],
            waypoints: [third, first, second, otherTour]
        )

        let result = catalogue.waypoints(for: "tower")

        #expect(result.map(\.id) == ["a", "b", "c"])
    }

    @Test("editorialPick(for:) returns the pick tour when it is published")
    func editorialPickReturnsPublishedPick() {
        let london = makeCity(id: "london", editorialPickTourID: "raleigh")
        let raleigh = makeTour(id: "raleigh", cityID: "london", status: .published)
        let catalogue = Catalogue(cities: [london], tours: [raleigh], waypoints: [])

        #expect(catalogue.editorialPick(for: "london")?.id == "raleigh")
    }

    @Test("editorialPick(for:) returns nil when the pick is not published")
    func editorialPickReturnsNilForUnpublishedPick() {
        let london = makeCity(id: "london", editorialPickTourID: "raleigh")
        let raleighDraft = makeTour(id: "raleigh", cityID: "london", status: .draft)
        let catalogue = Catalogue(cities: [london], tours: [raleighDraft], waypoints: [])

        #expect(catalogue.editorialPick(for: "london") == nil)
    }

    @Test("editorialPick(for:) returns nil when the city has no pick set")
    func editorialPickReturnsNilForCityWithoutPick() {
        let london = makeCity(id: "london", editorialPickTourID: nil)
        let raleigh = makeTour(id: "raleigh", cityID: "london", status: .published)
        let catalogue = Catalogue(cities: [london], tours: [raleigh], waypoints: [])

        #expect(catalogue.editorialPick(for: "london") == nil)
    }

    @Test("toursGroupedByEra groups published tours by era and sorts groups chronologically")
    func toursGroupedByEraSortsChronologically() {
        let london = makeCity(id: "london")
        let medieval = makeTour(id: "tower", cityID: "london", status: .published, era: "Medieval", eraStartYear: 1100)
        let victorian = makeTour(id: "fog", cityID: "london", status: .published, era: "Victorian", eraStartYear: 1837)
        let georgian = makeTour(id: "georgian", cityID: "london", status: .published, era: "Georgian", eraStartYear: 1714)
        let medievalDraft = makeTour(id: "joust", cityID: "london", status: .draft, era: "Medieval", eraStartYear: 1100)
        let catalogue = Catalogue(
            cities: [london],
            tours: [victorian, medieval, georgian, medievalDraft],
            waypoints: []
        )

        let groups = catalogue.toursGroupedByEra()

        #expect(groups.map(\.era) == ["Medieval", "Georgian", "Victorian"])
        #expect(groups.first(where: { $0.era == "Medieval" })?.tours.map(\.id) == ["tower"])
    }

    @Test("publishedCities excludes cities whose only tours are draft or archived")
    func publishedCitiesExcludesCitiesWithoutPublishedTours() {
        let london = makeCity(id: "london")
        let york = makeCity(id: "york")
        let bath = makeCity(id: "bath")
        let publishedInLondon = makeTour(id: "tower", cityID: "london", status: .published)
        let draftInYork = makeTour(id: "york-mystery", cityID: "york", status: .draft)
        let archivedInBath = makeTour(id: "bath-romans", cityID: "bath", status: .archived)
        let catalogue = Catalogue(
            cities: [london, york, bath],
            tours: [publishedInLondon, draftInYork, archivedInBath],
            waypoints: []
        )

        let result = catalogue.publishedCities()

        #expect(result.map(\.id) == ["london"])
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
    status: TourContentStatus,
    era: String = "Medieval",
    eraStartYear: Int = 1100
) -> Tour {
    Tour(
        id: id,
        title: id,
        city: cityID,
        theme: "theme",
        era: era,
        eraStartYear: eraStartYear,
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
    order: Int
) -> Waypoint {
    Waypoint(
        id: id,
        tourID: tourID,
        order: order,
        title: id,
        latitude: 0,
        longitude: 0,
        triggerRadiusM: 30,
        audioURL: URL(string: "https://example.com/a.mp3")!,
        transitionAudioURL: nil
    )
}
