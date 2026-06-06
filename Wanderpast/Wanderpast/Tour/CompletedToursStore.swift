import Foundation
import WanderpastCore

/// Persists which tours the user has finished, so library cards can show a
/// "completed" marker across app launches. Thin UserDefaults wrapper around
/// the pure `CompletedTours` value type from WanderpastCore.
@MainActor
final class CompletedToursStore: ObservableObject {
    private static let storageKey = "wanderpast.completedTours.v1"

    @Published private(set) var tours: CompletedTours

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(CompletedTours.self, from: data) {
            self.tours = decoded
        } else {
            self.tours = CompletedTours()
        }
    }

    func isCompleted(tourID: String) -> Bool {
        tours.isCompleted(tourID: tourID)
    }

    func markCompleted(tourID: String) {
        guard !tours.isCompleted(tourID: tourID) else { return }
        tours.markCompleted(tourID: tourID)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(tours) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
