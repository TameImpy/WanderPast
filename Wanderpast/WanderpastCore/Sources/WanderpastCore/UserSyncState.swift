import Foundation

public enum UserSyncState: Equatable, Sendable {
    case idle
    case syncing
    case synced(at: Date)
    case failed(retryable: Bool)
}

public enum UserSyncFailure: Equatable, Sendable {
    case network
    case server
    case auth
}

public enum UserSyncEvent: Equatable, Sendable {
    case begin
    case succeeded(at: Date)
    case failed(UserSyncFailure)
}

extension UserSyncState {
    public func advanced(by event: UserSyncEvent) -> UserSyncState {
        switch event {
        case .begin:
            return .syncing
        case .succeeded(let at):
            return .synced(at: at)
        case .failed(let failure):
            switch failure {
            case .network, .server:
                return .failed(retryable: true)
            case .auth:
                return .failed(retryable: false)
            }
        }
    }
}
