import Combine
import Foundation
import WanderpastCore

/// Combines the catalogue repository stream with a `LiveLocationProvider` to produce a
/// `NearbyToursState`. All mapping is delegated to `NearbyToursState.from(...)` in
/// WanderpastCore — this class is the live plumbing only.
@MainActor
final class NearbyToursViewModel: ObservableObject {
    @Published private(set) var state: NearbyToursState = .hidden

    private let repository: CatalogueRepository
    private let locationProvider: LiveLocationProvider
    private let radiusMeters: Double?

    private var lastLoadResult: CatalogueRepository.LoadResult?
    private var loadTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    init(
        repository: CatalogueRepository,
        locationProvider: LiveLocationProvider,
        radiusMeters: Double? = 50_000
    ) {
        self.repository = repository
        self.locationProvider = locationProvider
        self.radiusMeters = radiusMeters

        locationProvider.$authorization
            .sink { [weak self] _ in self?.recompute() }
            .store(in: &cancellables)
        locationProvider.$userLocation
            .sink { [weak self] _ in self?.recompute() }
            .store(in: &cancellables)
    }

    deinit {
        loadTask?.cancel()
    }

    func start() {
        if locationProvider.authorization == .notDetermined {
            locationProvider.requestAuthorization()
        } else if locationProvider.authorization == .granted {
            locationProvider.startUpdating()
        }
        loadCatalogue()
    }

    func retry() {
        loadCatalogue()
    }

    private func loadCatalogue() {
        loadTask?.cancel()
        loadTask = Task { [repository] in
            for await result in repository.loadCatalogue() {
                if Task.isCancelled { return }
                self.lastLoadResult = result
                self.recompute()
            }
        }
    }

    private func recompute() {
        state = NearbyToursState.from(
            authorization: locationProvider.authorization,
            userLocation: locationProvider.userLocation,
            loadResult: lastLoadResult,
            radiusMeters: radiusMeters
        )
    }
}
