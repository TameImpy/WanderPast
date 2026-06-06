/// A persistable set of tour IDs the user has finished end-to-end.
/// Codable for storage in UserDefaults via a thin wrapper in the app target.
public struct CompletedTours: Codable, Sendable, Equatable {
    private var tourIDs: Set<String>

    public init(tourIDs: Set<String> = []) {
        self.tourIDs = tourIDs
    }

    public var count: Int { tourIDs.count }

    public func isCompleted(tourID: String) -> Bool {
        tourIDs.contains(tourID)
    }

    public mutating func markCompleted(tourID: String) {
        tourIDs.insert(tourID)
    }
}
