import Foundation

public struct EraGroup: Sendable, Equatable {
    public let era: String
    public let eraStartYear: Int
    public let tours: [Tour]
}

public struct CityRow: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let heroImageURL: URL?
    public let publishedTourCount: Int

    public init(
        id: String,
        name: String,
        description: String,
        heroImageURL: URL?,
        publishedTourCount: Int
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.heroImageURL = heroImageURL
        self.publishedTourCount = publishedTourCount
    }
}

extension Tour: Equatable {
    public static func == (lhs: Tour, rhs: Tour) -> Bool { lhs.id == rhs.id }
}

extension Catalogue {
    /// Cities that have at least one published tour.
    public func publishedCities() -> [City] {
        let cityIDsWithPublishedTours = Set(
            tours.filter { $0.status == .published }.map(\.city)
        )
        return cities.filter { cityIDsWithPublishedTours.contains($0.id) }
    }

    /// Tour with the given ID, regardless of status, or nil if not present.
    public func tour(id: String) -> Tour? {
        tours.first { $0.id == id }
    }

    /// Waypoints belonging to the given tour, sorted by `order`.
    public func waypoints(for tourID: String) -> [Waypoint] {
        waypoints
            .filter { $0.tourID == tourID }
            .sorted { $0.order < $1.order }
    }

    /// Published tours for the given city, with the editorial pick first when set.
    public func tours(in cityID: String) -> [Tour] {
        let published = tours.filter { $0.city == cityID && $0.status == .published }
        guard let pickID = cities.first(where: { $0.id == cityID })?.editorialPickTourID,
              let pickIndex = published.firstIndex(where: { $0.id == pickID })
        else { return published }
        var reordered = published
        let pick = reordered.remove(at: pickIndex)
        reordered.insert(pick, at: 0)
        return reordered
    }

    /// Published tours grouped by era, with groups sorted chronologically by `eraStartYear`.
    public func toursGroupedByEra() -> [EraGroup] {
        let published = tours.filter { $0.status == .published }
        let grouped = Dictionary(grouping: published, by: \.era)
        return grouped
            .map { era, tours in
                let year = tours.first?.eraStartYear ?? 0
                return EraGroup(era: era, eraStartYear: year, tours: tours)
            }
            .sorted { $0.eraStartYear < $1.eraStartYear }
    }

    /// Rows for the city browse screen — one per city with at least one published tour,
    /// with `publishedTourCount` derived from the catalogue rather than the static field.
    /// Preserves the catalogue's city ordering.
    public func cityRows() -> [CityRow] {
        var publishedCountByCity: [String: Int] = [:]
        for tour in tours where tour.status == .published {
            publishedCountByCity[tour.city, default: 0] += 1
        }
        return cities.compactMap { city in
            guard let count = publishedCountByCity[city.id], count > 0 else { return nil }
            return CityRow(
                id: city.id,
                name: city.name,
                description: city.description,
                heroImageURL: city.heroImageURL,
                publishedTourCount: count
            )
        }
    }

    /// The city's editorial pick tour, if one is set and currently published.
    public func editorialPick(for cityID: String) -> Tour? {
        guard let pickID = cities.first(where: { $0.id == cityID })?.editorialPickTourID,
              let pick = tour(id: pickID),
              pick.status == .published
        else { return nil }
        return pick
    }
}
