import Foundation

public enum CachePolicyDecision: Equatable, Sendable {
    case useCache
    case refetchAndUseFresh
    case refetchInBackgroundButShowCache
    case showError
}

public enum CachePolicy {
    public static let defaultTTL: TimeInterval = 60 * 60   // 1 hour

    public static func decide(
        lastFetchDate: Date?,
        now: Date,
        networkAvailable: Bool,
        hasCachedData: Bool,
        ttl: TimeInterval = defaultTTL
    ) -> CachePolicyDecision {
        if !hasCachedData {
            return networkAvailable ? .refetchAndUseFresh : .showError
        }
        let age = now.timeIntervalSince(lastFetchDate ?? .distantPast)
        let isFresh = age < ttl
        if isFresh { return .useCache }
        return networkAvailable ? .refetchInBackgroundButShowCache : .useCache
    }
}
