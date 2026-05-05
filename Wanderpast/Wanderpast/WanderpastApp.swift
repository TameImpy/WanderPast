import SwiftUI

@main
struct WanderpastApp: App {
    @StateObject private var coordinator = TourCoordinator()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TourDetailView(coordinator: coordinator)
            }
        }
    }
}
