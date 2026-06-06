import Foundation
import Testing
@testable import WanderpastCore

@Suite("CompletedTours")
struct CompletedToursTests {

    @Test("A fresh CompletedTours contains no tours")
    func empty() {
        let tours = CompletedTours()

        #expect(tours.count == 0)
        #expect(tours.isCompleted(tourID: "tower-of-london-prisoners") == false)
    }

    @Test("Marking a tour completed makes isCompleted return true for that ID only")
    func markCompleted() {
        var tours = CompletedTours()

        tours.markCompleted(tourID: "tower-of-london-prisoners")

        #expect(tours.count == 1)
        #expect(tours.isCompleted(tourID: "tower-of-london-prisoners") == true)
        #expect(tours.isCompleted(tourID: "york-shambles") == false)
    }

    @Test("Marking the same tour twice does not duplicate")
    func markCompletedIsIdempotent() {
        var tours = CompletedTours()

        tours.markCompleted(tourID: "tower-of-london-prisoners")
        tours.markCompleted(tourID: "tower-of-london-prisoners")

        #expect(tours.count == 1)
    }

    @Test("allIDs returns every completed tour ID, suitable for sync payloads")
    func allIDsReturnsEveryCompletedID() {
        var tours = CompletedTours()
        tours.markCompleted(tourID: "tower-of-london-prisoners")
        tours.markCompleted(tourID: "york-shambles")

        #expect(Set(tours.allIDs) == ["tower-of-london-prisoners", "york-shambles"])
    }

    @Test("Codable round-trip preserves the set of completed tour IDs")
    func codableRoundTrip() throws {
        var tours = CompletedTours()
        tours.markCompleted(tourID: "tower-of-london-prisoners")
        tours.markCompleted(tourID: "york-shambles")

        let data = try JSONEncoder().encode(tours)
        let decoded = try JSONDecoder().decode(CompletedTours.self, from: data)

        #expect(decoded == tours)
        #expect(decoded.isCompleted(tourID: "tower-of-london-prisoners") == true)
        #expect(decoded.isCompleted(tourID: "york-shambles") == true)
    }
}
