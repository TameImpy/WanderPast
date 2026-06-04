import Testing
import Foundation
@testable import WanderpastCore

@Suite("CachePolicy")
struct CachePolicyTests {

    @Test("No cache + network available → refetchAndUseFresh")
    func coldStartWithNetwork() {
        let decision = CachePolicy.decide(
            lastFetchDate: nil,
            now: Date(),
            networkAvailable: true,
            hasCachedData: false
        )

        #expect(decision == .refetchAndUseFresh)
    }

    @Test("Fresh cache (within TTL) + network → useCache")
    func freshCacheUsesCache() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let fiveMinAgo = now.addingTimeInterval(-5 * 60)

        let decision = CachePolicy.decide(
            lastFetchDate: fiveMinAgo,
            now: now,
            networkAvailable: true,
            hasCachedData: true
        )

        #expect(decision == .useCache)
    }

    @Test("Stale cache + network → refetchInBackgroundButShowCache")
    func staleCacheWithNetwork() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let twoHoursAgo = now.addingTimeInterval(-2 * 60 * 60)

        let decision = CachePolicy.decide(
            lastFetchDate: twoHoursAgo,
            now: now,
            networkAvailable: true,
            hasCachedData: true
        )

        #expect(decision == .refetchInBackgroundButShowCache)
    }

    @Test("Stale cache + offline → useCache")
    func staleCacheOffline() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let twoHoursAgo = now.addingTimeInterval(-2 * 60 * 60)

        let decision = CachePolicy.decide(
            lastFetchDate: twoHoursAgo,
            now: now,
            networkAvailable: false,
            hasCachedData: true
        )

        #expect(decision == .useCache)
    }

    @Test("No cache + offline → showError")
    func coldStartOffline() {
        let decision = CachePolicy.decide(
            lastFetchDate: nil,
            now: Date(),
            networkAvailable: false,
            hasCachedData: false
        )

        #expect(decision == .showError)
    }
}
