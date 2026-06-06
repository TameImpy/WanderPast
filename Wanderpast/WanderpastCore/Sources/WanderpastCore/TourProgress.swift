/// Human-friendly progress through a tour, used for "Stop N of M" indicators in the UI.
///
/// `currentStopNumber` is 1-indexed and reflects the stop the user is *currently engaged with*:
/// the waypoint playing right now, or — between waypoints — the one they are walking toward.
/// It is `0` only before a tour has started.
public struct TourProgress: Sendable, Equatable {
    public let currentStopNumber: Int
    public let totalStops: Int

    public init(currentStopNumber: Int, totalStops: Int) {
        self.currentStopNumber = currentStopNumber
        self.totalStops = totalStops
    }
}
