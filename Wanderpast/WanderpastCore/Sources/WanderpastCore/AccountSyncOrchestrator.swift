import Foundation

public struct LocalUserSnapshot: Equatable, Sendable {
    public let completedTourIDs: [String]
    public let ownedProductIDs: [String]

    public init(completedTourIDs: [String], ownedProductIDs: [String]) {
        self.completedTourIDs = completedTourIDs
        self.ownedProductIDs = ownedProductIDs
    }
}

public enum AccountSyncOrchestrator {
    public static func sync(
        stableID: String,
        local: LocalUserSnapshot,
        backend: BackendUserClient,
        now: Date
    ) async throws -> RemoteUserPayload {
        let localPayload = RemoteUserPayload(
            stableID: stableID,
            completedTourIDs: local.completedTourIDs,
            ownedProductIDs: local.ownedProductIDs,
            updatedAt: now
        )

        let remote = try await backend.fetch(stableID: stableID)
        let merged: RemoteUserPayload
        if let remote {
            merged = RemoteUserPayload.merging(local: localPayload, remote: remote)
        } else {
            merged = localPayload
        }

        return try await backend.upsert(merged)
    }
}
