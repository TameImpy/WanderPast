import Foundation
import Combine
import WanderpastCore

/// Owns the user's signed-in identity, drives sign-in/out, and orchestrates
/// catalogue-state sync with the backend. Persists the current identity via
/// `UserDefaults` so the signed-in state survives app launches; on a fresh
/// install the user signs in again and `AccountSyncOrchestrator` restores
/// their completed tours from the backend.
@MainActor
final class AccountStore: ObservableObject {
    private static let identityStorageKey = "wanderpast.account.identity.v1"

    @Published private(set) var state: AccountState
    @Published private(set) var syncState: UserSyncState = .idle

    private let defaults: UserDefaults
    private let backend: BackendUserClient
    private let signInController: AppleSignInController
    private weak var completedToursStore: CompletedToursStore?
    private var cancellables: Set<AnyCancellable> = []

    init(
        defaults: UserDefaults = .standard,
        backend: BackendUserClient,
        signInController: AppleSignInController? = nil
    ) {
        let resolvedController = signInController ?? AppleSignInController()
        self.defaults = defaults
        self.backend = backend
        self.signInController = resolvedController

        if let data = defaults.data(forKey: Self.identityStorageKey),
           let identity = try? JSONDecoder().decode(AccountIdentity.self, from: data) {
            self.state = .signedIn(identity)
        } else {
            self.state = .signedOut
        }
    }

    /// Wire up sync triggers — call once after construction. When the user
    /// finishes a tour while signed in, push the updated completion set to
    /// the backend so a future fresh install can restore it.
    func attach(completedToursStore: CompletedToursStore) {
        self.completedToursStore = completedToursStore
        completedToursStore.$tours
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.syncIfSignedIn() }
            }
            .store(in: &cancellables)
    }

    func signIn() async {
        syncState = .syncing
        do {
            let identity = try await signInController.signIn()
            persist(identity: identity)
            state = .signedIn(identity)
            try await runSync(stableID: identity.stableID)
        } catch AppleSignInController.SignInError.cancelled {
            syncState = .idle
        } catch {
            syncState = syncState.advanced(by: .failed(.auth))
        }
    }

    func signOut() {
        defaults.removeObject(forKey: Self.identityStorageKey)
        state = .signedOut
        syncState = .idle
    }

    func syncIfSignedIn() async {
        guard case .signedIn(let identity) = state else { return }
        syncState = syncState.advanced(by: .begin)
        do {
            try await runSync(stableID: identity.stableID)
        } catch {
            syncState = syncState.advanced(by: .failed(.network))
        }
    }

    private func runSync(stableID: String) async throws {
        let snapshot = LocalUserSnapshot(
            completedTourIDs: completedToursStore?.tours.allIDs.sorted() ?? [],
            ownedProductIDs: []
        )
        let merged = try await AccountSyncOrchestrator.sync(
            stableID: stableID,
            local: snapshot,
            backend: backend,
            now: Date()
        )
        applyRemote(merged)
        syncState = .synced(at: merged.updatedAt)
    }

    private func applyRemote(_ payload: RemoteUserPayload) {
        guard let store = completedToursStore else { return }
        for tourID in payload.completedTourIDs where !store.isCompleted(tourID: tourID) {
            store.markCompleted(tourID: tourID)
        }
    }

    private func persist(identity: AccountIdentity) {
        if let data = try? JSONEncoder().encode(identity) {
            defaults.set(data, forKey: Self.identityStorageKey)
        }
    }
}
