import Testing
import Foundation
@testable import WanderpastCore

@Suite("CatalogueRepository")
struct CatalogueRepositoryTests {

    @Test("Cold start with network: yields .fresh and writes to cache")
    func coldStartWithNetwork() async {
        let fetcher = FakeFetcher()
        fetcher.set(payload: validJSON, for: testURL)
        let cache = FakeCache()
        let repo = CatalogueRepository(
            fetcher: fetcher,
            cache: cache,
            url: testURL,
            networkAvailable: { true }
        )

        let results = await collect(repo.loadCatalogue())

        #expect(results.count == 1)
        if case .fresh(let cat) = results.first {
            #expect(cat.tours.first?.id == "tower")
        } else {
            Issue.record("expected .fresh, got \(String(describing: results.first))")
        }
        #expect(cache.savedData == validJSON)
    }

    @Test("Fetch succeeds but parse fails: yields .failure(.parseFailed) and preserves cache")
    func parseFailurePreservesCache() async {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let cache = FakeCache()
        cache.prefillCache(data: validJSON, savedAt: now.addingTimeInterval(-2 * 60 * 60))
        let fetcher = FakeFetcher()
        let malformed = "{ not json".data(using: .utf8)!
        fetcher.set(payload: malformed, for: testURL)
        let repo = CatalogueRepository(
            fetcher: fetcher,
            cache: cache,
            url: testURL,
            now: { now },
            networkAvailable: { true }
        )

        let results = await collect(repo.loadCatalogue())

        // First yield is .cached (stale), then attempt fetch which fails parse
        #expect(results.count == 2)
        if case .failure(let err) = results.last,
           case .parseFailed = err {
            // expected
        } else {
            Issue.record("expected .failure(.parseFailed) last, got \(String(describing: results.last))")
        }
        #expect(cache.savedData == validJSON, "cache should not be overwritten with bad data")
    }

    @Test("Offline with stale cache: yields .cached(isStale: true) and skips network")
    func offlineWithStaleCache() async {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let cache = FakeCache()
        cache.prefillCache(data: validJSON, savedAt: now.addingTimeInterval(-2 * 60 * 60))
        let fetcher = FakeFetcher()
        let repo = CatalogueRepository(
            fetcher: fetcher,
            cache: cache,
            url: testURL,
            now: { now },
            networkAvailable: { false }
        )

        let results = await collect(repo.loadCatalogue())

        #expect(results.count == 1)
        if case .cached(_, let isStale) = results.first {
            #expect(isStale == true)
        } else {
            Issue.record("expected .cached, got \(String(describing: results.first))")
        }
        #expect(fetcher.callCount == 0)
    }

    @Test("Offline with no cache: yields .failure(.offline)")
    func offlineWithNoCache() async {
        let cache = FakeCache()
        let fetcher = FakeFetcher()
        let repo = CatalogueRepository(
            fetcher: fetcher,
            cache: cache,
            url: testURL,
            networkAvailable: { false }
        )

        let results = await collect(repo.loadCatalogue())

        #expect(results.count == 1)
        if case .failure(let err) = results.first,
           case .offline = err {
            #expect(fetcher.callCount == 0)
        } else {
            Issue.record("expected .failure(.offline), got \(String(describing: results.first))")
        }
    }

    @Test("Stale cache with network: yields .cached(isStale: true) then .fresh")
    func staleCacheWithNetworkYieldsCachedThenFresh() async {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let cache = FakeCache()
        cache.prefillCache(data: validJSON, savedAt: now.addingTimeInterval(-2 * 60 * 60))
        let updatedJSON = validJSON  // for simplicity, fetcher returns same payload
        let fetcher = FakeFetcher()
        fetcher.set(payload: updatedJSON, for: testURL)
        let repo = CatalogueRepository(
            fetcher: fetcher,
            cache: cache,
            url: testURL,
            now: { now },
            networkAvailable: { true }
        )

        let results = await collect(repo.loadCatalogue())

        #expect(results.count == 2)
        if case .cached(_, let isStale) = results.first {
            #expect(isStale == true)
        } else {
            Issue.record("expected .cached first")
        }
        if case .fresh = results.last {
            #expect(fetcher.callCount == 1)
        } else {
            Issue.record("expected .fresh second")
        }
    }

    @Test("Fresh cache within TTL: yields .cached(isStale: false) and skips network")
    func freshCacheUsesCache() async {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let cache = FakeCache()
        cache.prefillCache(data: validJSON, savedAt: now.addingTimeInterval(-5 * 60))
        let fetcher = FakeFetcher()
        let repo = CatalogueRepository(
            fetcher: fetcher,
            cache: cache,
            url: testURL,
            now: { now },
            networkAvailable: { true }
        )

        let results = await collect(repo.loadCatalogue())

        #expect(results.count == 1)
        if case .cached(let cat, let isStale) = results.first {
            #expect(cat.tours.first?.id == "tower")
            #expect(isStale == false)
        } else {
            Issue.record("expected .cached, got \(String(describing: results.first))")
        }
        #expect(fetcher.callCount == 0)
    }
}

// MARK: - Shared helpers

let testURL = URL(string: "https://example.com/catalogue.json")!

let validJSON: Data = """
{
  "cities": [{
    "id": "london", "name": "London", "description": "...",
    "hero_image_url": null, "tour_count": 1,
    "editorial_pick_tour_id": null, "general_accessibility_note": null
  }],
  "tours": [{
    "id": "tower", "title": "Tower", "city": "london", "theme": "T",
    "era": "Medieval", "era_start_year": 1100,
    "narration_style": "present_tense_omniscient",
    "narrator_name": "N", "narrator_bio": "B",
    "duration_minutes": 30, "waypoint_count": 0,
    "description": "D", "preview_clip_url": null,
    "ambient_soundscape_url": null, "completion_summary": "C",
    "hero_image_url": null, "is_free": true, "price_tier": "free",
    "status": "published"
  }],
  "waypoints": []
}
""".data(using: .utf8)!

func collect<T>(_ stream: AsyncStream<T>) async -> [T] {
    var out: [T] = []
    for await item in stream { out.append(item) }
    return out
}

final class FakeFetcher: CatalogueFetching, @unchecked Sendable {
    var responses: [URL: Result<Data, Error>] = [:]
    var callCount: Int = 0

    func set(payload: Data, for url: URL) {
        responses[url] = .success(payload)
    }

    func setFailure(_ error: Error, for url: URL) {
        responses[url] = .failure(error)
    }

    func fetch(from url: URL) async throws -> Data {
        callCount += 1
        switch responses[url] {
        case .success(let data): return data
        case .failure(let error): throw error
        case nil: throw CatalogueFetchError.unexpectedResponse
        }
    }
}

final class FakeCache: CatalogueCaching, @unchecked Sendable {
    var savedData: Data?
    var fakeDate: Date?

    func save(data: Data) throws {
        savedData = data
        if fakeDate == nil { fakeDate = Date() }
    }

    func loadCachedData() -> Data? { savedData }

    var lastFetchDate: Date? { fakeDate }

    func prefillCache(data: Data, savedAt: Date) {
        savedData = data
        fakeDate = savedAt
    }
}
