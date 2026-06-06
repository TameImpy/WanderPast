import Foundation
import Testing
@testable import WanderpastCore

@Suite("RemoteUserPayload.merging")
struct RemoteUserPayloadMergeTests {

    @Test("Merging unions completed tour IDs from local and remote, deduplicated and sorted")
    func unionsCompletedTours() {
        let local = RemoteUserPayload(
            stableID: "001234.abcd.5678",
            completedTourIDs: ["tower-of-london-prisoners", "york-shambles"],
            ownedProductIDs: [],
            updatedAt: Date(timeIntervalSince1970: 1_750_000_100)
        )
        let remote = RemoteUserPayload(
            stableID: "001234.abcd.5678",
            completedTourIDs: ["york-shambles", "bath-roman-baths"],
            ownedProductIDs: [],
            updatedAt: Date(timeIntervalSince1970: 1_750_000_000)
        )

        let merged = RemoteUserPayload.merging(local: local, remote: remote)

        #expect(merged.completedTourIDs == ["bath-roman-baths", "tower-of-london-prisoners", "york-shambles"])
    }

    @Test("Merging unions owned product IDs and stamps updated_at as the max of the two")
    func unionsProductsAndTakesLatestTimestamp() {
        let earlier = Date(timeIntervalSince1970: 1_750_000_000)
        let later = Date(timeIntervalSince1970: 1_750_000_500)

        let local = RemoteUserPayload(
            stableID: "001234.abcd.5678",
            completedTourIDs: [],
            ownedProductIDs: ["tour.tower-of-london-prisoners"],
            updatedAt: earlier
        )
        let remote = RemoteUserPayload(
            stableID: "001234.abcd.5678",
            completedTourIDs: [],
            ownedProductIDs: ["tour.tower-of-london-prisoners", "city.london"],
            updatedAt: later
        )

        let merged = RemoteUserPayload.merging(local: local, remote: remote)

        #expect(merged.ownedProductIDs == ["city.london", "tour.tower-of-london-prisoners"])
        #expect(merged.updatedAt == later)
    }
}
