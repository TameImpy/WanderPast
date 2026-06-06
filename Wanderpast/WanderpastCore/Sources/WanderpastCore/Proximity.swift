import Foundation

public struct Coordinate: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct NearbyTour: Equatable, Sendable {
    public let tour: Tour
    public let distanceMeters: Double
    public let startCoordinate: Coordinate

    public init(tour: Tour, distanceMeters: Double, startCoordinate: Coordinate) {
        self.tour = tour
        self.distanceMeters = distanceMeters
        self.startCoordinate = startCoordinate
    }
}

extension Catalogue {
    /// Published tours measured by haversine distance from `origin` to the first ordered
    /// waypoint, sorted ascending. Tours with no waypoints are excluded. If `maxMeters`
    /// is non-nil, tours beyond it are excluded.
    public func nearbyTours(from origin: Coordinate, within maxMeters: Double?) -> [NearbyTour] {
        let published = tours.filter { $0.status == .published }
        let ranked: [NearbyTour] = published.compactMap { tour in
            guard let first = waypoints(for: tour.id).first else { return nil }
            let start = Coordinate(latitude: first.latitude, longitude: first.longitude)
            let distance = haversineMeters(origin, start)
            if let cap = maxMeters, distance > cap { return nil }
            return NearbyTour(tour: tour, distanceMeters: distance, startCoordinate: start)
        }
        return ranked.sorted { $0.distanceMeters < $1.distanceMeters }
    }
}

/// Great-circle distance in metres between two coordinates on the WGS-84 sphere.
func haversineMeters(_ a: Coordinate, _ b: Coordinate) -> Double {
    let earthRadiusMeters = 6_371_000.0
    let lat1 = a.latitude * .pi / 180
    let lat2 = b.latitude * .pi / 180
    let dLat = (b.latitude - a.latitude) * .pi / 180
    let dLon = (b.longitude - a.longitude) * .pi / 180
    let h = sin(dLat / 2) * sin(dLat / 2)
        + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
    let c = 2 * atan2(sqrt(h), sqrt(1 - h))
    return earthRadiusMeters * c
}
