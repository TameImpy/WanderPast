import Foundation

public protocol BackendUserClient: Sendable {
    func fetch(stableID: String) async throws -> RemoteUserPayload?
    func upsert(_ payload: RemoteUserPayload) async throws -> RemoteUserPayload
}

public actor InMemoryBackendUserClient: BackendUserClient {
    private var store: [String: RemoteUserPayload] = [:]

    public init() {}

    public func fetch(stableID: String) async throws -> RemoteUserPayload? {
        store[stableID]
    }

    public func upsert(_ payload: RemoteUserPayload) async throws -> RemoteUserPayload {
        store[payload.stableID] = payload
        return payload
    }
}
