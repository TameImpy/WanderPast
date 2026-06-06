import Foundation
import Testing
@testable import WanderpastCore

@Suite("RemoteUserPayload")
struct RemoteUserPayloadTests {

    @Test("Encodes with snake_case keys and ISO8601 updated_at, decodes back to equal value")
    func wireFormatRoundTrip() throws {
        let payload = RemoteUserPayload(
            stableID: "001234.abcd.5678",
            completedTourIDs: ["tower-of-london-prisoners", "york-shambles"],
            ownedProductIDs: ["tour.tower-of-london-prisoners"],
            updatedAt: Date(timeIntervalSince1970: 1_750_000_000)
        )

        let data = try RemoteUserPayload.wireEncoder.encode(payload)
        let json = String(decoding: data, as: UTF8.self)

        #expect(json.contains("\"stable_id\":\"001234.abcd.5678\""))
        #expect(json.contains("\"completed_tour_ids\""))
        #expect(json.contains("\"owned_product_ids\""))
        #expect(json.contains("\"updated_at\""))

        let decoded = try RemoteUserPayload.wireDecoder.decode(RemoteUserPayload.self, from: data)
        #expect(decoded == payload)
    }

    @Test("A sparse backend response with no array fields decodes to empty lists")
    func decodesSparseResponseAsEmptyLists() throws {
        let json = #"""
        {
            "stable_id": "001234.abcd.5678",
            "updated_at": "2026-06-06T12:00:00Z"
        }
        """#.data(using: .utf8)!

        let decoded = try RemoteUserPayload.wireDecoder.decode(RemoteUserPayload.self, from: json)

        #expect(decoded.stableID == "001234.abcd.5678")
        #expect(decoded.completedTourIDs == [])
        #expect(decoded.ownedProductIDs == [])
    }
}
