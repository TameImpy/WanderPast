import Foundation
import Testing
@testable import WanderpastCore

@Suite("AccountSyncOrchestrator")
struct AccountSyncOrchestratorTests {

    @Test("First sync for a new user uploads the local snapshot and returns it as the merged result")
    func firstSyncForNewUser() async throws {
        let client = InMemoryBackendUserClient()
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let local = LocalUserSnapshot(
            completedTourIDs: ["tower-of-london-prisoners"],
            ownedProductIDs: []
        )

        let merged = try await AccountSyncOrchestrator.sync(
            stableID: "001234.abcd.5678",
            local: local,
            backend: client,
            now: now
        )

        #expect(merged.stableID == "001234.abcd.5678")
        #expect(merged.completedTourIDs == ["tower-of-london-prisoners"])
        #expect(merged.ownedProductIDs == [])

        let stored = try await client.fetch(stableID: "001234.abcd.5678")
        #expect(stored == merged)
    }

    @Test("Second sync merges local and remote completed tours, then uploads the union")
    func secondSyncMergesLocalAndRemote() async throws {
        let client = InMemoryBackendUserClient()
        let earlier = Date(timeIntervalSince1970: 1_750_000_000)
        let now = Date(timeIntervalSince1970: 1_750_000_500)

        _ = try await client.upsert(RemoteUserPayload(
            stableID: "001234.abcd.5678",
            completedTourIDs: ["bath-roman-baths"],
            ownedProductIDs: ["city.bath"],
            updatedAt: earlier
        ))

        let local = LocalUserSnapshot(
            completedTourIDs: ["tower-of-london-prisoners"],
            ownedProductIDs: ["tour.tower-of-london-prisoners"]
        )

        let merged = try await AccountSyncOrchestrator.sync(
            stableID: "001234.abcd.5678",
            local: local,
            backend: client,
            now: now
        )

        #expect(merged.completedTourIDs == ["bath-roman-baths", "tower-of-london-prisoners"])
        #expect(merged.ownedProductIDs == ["city.bath", "tour.tower-of-london-prisoners"])
        #expect(merged.updatedAt == now)
    }
}
