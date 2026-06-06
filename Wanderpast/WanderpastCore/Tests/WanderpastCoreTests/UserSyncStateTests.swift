import Foundation
import Testing
@testable import WanderpastCore

@Suite("UserSyncState")
struct UserSyncStateTests {

    @Test("Beginning a sync transitions idle to syncing")
    func beginFromIdle() {
        let state = UserSyncState.idle.advanced(by: .begin)
        #expect(state == .syncing)
    }

    @Test("Beginning a sync transitions a prior synced state back to syncing")
    func beginFromSynced() {
        let at = Date(timeIntervalSince1970: 1_750_000_000)
        let state = UserSyncState.synced(at: at).advanced(by: .begin)
        #expect(state == .syncing)
    }

    @Test("Beginning a sync transitions a prior failed state back to syncing")
    func beginFromFailed() {
        let state = UserSyncState.failed(retryable: true).advanced(by: .begin)
        #expect(state == .syncing)
    }

    @Test("A successful sync transitions syncing to synced(at:) with the supplied date")
    func succeededFromSyncing() {
        let at = Date(timeIntervalSince1970: 1_750_000_000)
        let state = UserSyncState.syncing.advanced(by: .succeeded(at: at))
        #expect(state == .synced(at: at))
    }

    @Test("A network failure is treated as retryable")
    func networkFailureIsRetryable() {
        let state = UserSyncState.syncing.advanced(by: .failed(.network))
        #expect(state == .failed(retryable: true))
    }

    @Test("A server failure is treated as retryable")
    func serverFailureIsRetryable() {
        let state = UserSyncState.syncing.advanced(by: .failed(.server))
        #expect(state == .failed(retryable: true))
    }

    @Test("An auth failure is not retryable — user must sign in again")
    func authFailureNotRetryable() {
        let state = UserSyncState.syncing.advanced(by: .failed(.auth))
        #expect(state == .failed(retryable: false))
    }
}
