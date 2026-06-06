import Foundation
import Testing
@testable import WanderpastCore

@Suite("InMemoryBackendUserClient")
struct InMemoryBackendUserClientTests {

    @Test("Fetching an unknown stableID returns nil")
    func fetchUnknownReturnsNil() async throws {
        let client = InMemoryBackendUserClient()

        let result = try await client.fetch(stableID: "001234.unknown")

        #expect(result == nil)
    }

    @Test("Upserting a payload then fetching the same stableID returns it")
    func upsertThenFetchRoundTrip() async throws {
        let client = InMemoryBackendUserClient()
        let payload = RemoteUserPayload(
            stableID: "001234.abcd.5678",
            completedTourIDs: ["tower-of-london-prisoners"],
            ownedProductIDs: ["tour.tower-of-london-prisoners"],
            updatedAt: Date(timeIntervalSince1970: 1_750_000_000)
        )

        _ = try await client.upsert(payload)
        let fetched = try await client.fetch(stableID: "001234.abcd.5678")

        #expect(fetched == payload)
    }
}
