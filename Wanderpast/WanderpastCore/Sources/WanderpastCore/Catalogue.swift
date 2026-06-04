import Foundation

public struct Catalogue: Codable, Sendable {
    public let cities: [City]
    public let tours: [Tour]
    public let waypoints: [Waypoint]
}
