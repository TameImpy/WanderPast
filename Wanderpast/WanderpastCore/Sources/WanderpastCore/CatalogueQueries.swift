import Foundation

public struct EraGroup: Sendable, Equatable {
    public let era: String
    public let eraStartYear: Int
    public let tours: [Tour]
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

    /// The city's editorial pick tour, if one is set and currently published.
    public func editorialPick(for cityID: String) -> Tour? {
        guard let pickID = cities.first(where: { $0.id == cityID })?.editorialPickTourID,
              let pick = tour(id: pickID),
              pick.status == .published
        else { return nil }
        return pick
    }
}
