import Foundation

public struct CatalogueRepository: Sendable {

    public enum LoadResult: Sendable {
        case fresh(Catalogue)
        case cached(Catalogue, isStale: Bool)
        case failure(CatalogueLoadError)
    }

    public enum CatalogueLoadError: Error, Sendable {
        case offline
        case fetchFailed(CatalogueFetchError)
        case parseFailed(CatalogueError)
    }

    private let fetcher: any CatalogueFetching
    private let cache: any CatalogueCaching
    private let url: URL
    private let ttl: TimeInterval
    private let now: @Sendable () -> Date
    private let networkAvailable: @Sendable () -> Bool

    public init(
        fetcher: any CatalogueFetching,
        cache: any CatalogueCaching,
        url: URL,
        ttl: TimeInterval = CachePolicy.defaultTTL,
        now: @escaping @Sendable () -> Date = { Date() },
        networkAvailable: @escaping @Sendable () -> Bool = { true }
    ) {
        self.fetcher = fetcher
        self.cache = cache
        self.url = url
        self.ttl = ttl
        self.now = now
        self.networkAvailable = networkAvailable
    }

    public func loadCatalogue() -> AsyncStream<LoadResult> {
        AsyncStream { continuation in
            Task {
                await runLoad(continuation: continuation)
                continuation.finish()
            }
        }
    }

    private func runLoad(continuation: AsyncStream<LoadResult>.Continuation) async {
        let decision = CachePolicy.decide(
            lastFetchDate: cache.lastFetchDate,
            now: now(),
            networkAvailable: networkAvailable(),
            hasCachedData: cache.loadCachedData() != nil,
            ttl: ttl
        )

        switch decision {
        case .refetchAndUseFresh:
            await fetchAndYield(continuation: continuation)
        case .useCache:
            yieldCached(continuation: continuation, isStale: cacheIsStale())
        case .refetchInBackgroundButShowCache:
            yieldCached(continuation: continuation, isStale: true)
            await fetchAndYield(continuation: continuation)
        case .showError:
            continuation.yield(.failure(.offline))
        }
    }

    private func cacheIsStale() -> Bool {
        guard let last = cache.lastFetchDate else { return true }
        return now().timeIntervalSince(last) >= ttl
    }

    private func fetchAndYield(continuation: AsyncStream<LoadResult>.Continuation) async {
        do {
            let data = try await fetcher.fetch(from: url)
            let catalogue = try CatalogueParser.parse(data: data)
            try? cache.save(data: data)
            continuation.yield(.fresh(catalogue))
        } catch let fetchError as CatalogueFetchError {
            continuation.yield(.failure(.fetchFailed(fetchError)))
        } catch let parseError as CatalogueError {
            continuation.yield(.failure(.parseFailed(parseError)))
        } catch {
            continuation.yield(.failure(.fetchFailed(.unexpectedResponse)))
        }
    }

    private func yieldCached(continuation: AsyncStream<LoadResult>.Continuation, isStale: Bool) {
        guard let data = cache.loadCachedData(),
              let catalogue = try? CatalogueParser.parse(data: data) else {
            continuation.yield(.failure(.offline))
            return
        }
        continuation.yield(.cached(catalogue, isStale: isStale))
    }
}
