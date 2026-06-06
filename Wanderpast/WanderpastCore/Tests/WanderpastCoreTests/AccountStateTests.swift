import Foundation
import Testing
@testable import WanderpastCore

@Suite("AccountState")
struct AccountStateTests {

    @Test("A signed-in state carries the identity that was used to sign in")
    func signedInCarriesIdentity() {
        let identity = AccountIdentity(
            stableID: "001234.abcd5678efgh.1234",
            fullName: "Eleanor Rance",
            email: "eleanor@example.com"
        )

        let state: AccountState = .signedIn(identity)

        #expect(state == .signedIn(identity))
        #expect(state != .signedOut)
    }

    @Test("AccountIdentity round-trips through JSON, preserving optional fullName and email")
    func identityCodableRoundTrip() throws {
        let identity = AccountIdentity(
            stableID: "001234.abcd5678efgh.1234",
            fullName: "Eleanor Rance",
            email: "eleanor@example.com"
        )

        let data = try JSONEncoder().encode(identity)
        let decoded = try JSONDecoder().decode(AccountIdentity.self, from: data)

        #expect(decoded == identity)
    }

    @Test("AccountIdentity decodes when fullName and email are absent")
    func identityDecodesWithoutOptionalFields() throws {
        let json = #"{"stableID":"001234.xyz.9876"}"#.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AccountIdentity.self, from: json)

        #expect(decoded.stableID == "001234.xyz.9876")
        #expect(decoded.fullName == nil)
        #expect(decoded.email == nil)
    }
}
