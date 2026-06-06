import MapKit
import SwiftUI
import WanderpastCore

/// In-tour UI: stop progress, controls, "Help I'm lost", and the post-tour completion card.
struct InTourView: View {
    @EnvironmentObject var coordinator: TourCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.warmPaper.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: WPSpacing.lg)
                progressBlock
                Spacer(minLength: WPSpacing.lg)
                controls
                helpImLostButton
                    .padding(.top, WPSpacing.lg)
                    .padding(.bottom, WPSpacing.xl)
            }
            .padding(.horizontal, WPSpacing.md)

            if coordinator.tourStatus == .completed,
               let tour = coordinator.tour {
                CompletionCardView(
                    tour: tour,
                    waypoints: coordinator.allWaypoints,
                    onDone: { dismiss() }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.tourStatus)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.stone)
                    .padding(WPSpacing.xs)
                    .background(Circle().fill(Color.parchment))
            }
            .accessibilityLabel("Close tour")
        }
        .padding(.top, WPSpacing.xs)
    }

    // MARK: - Progress block

    private var progressBlock: some View {
        VStack(spacing: WPSpacing.sm) {
            Text(stopOverline)
                .font(.overline)
                .tracking(2)
                .foregroundStyle(Color.stone)

            if let title = coordinator.currentWaypointTitle {
                Text(title)
                    .font(.displayMedium)
                    .foregroundStyle(Color.deepInk)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, WPSpacing.sm)
            } else {
                Text(idleHeadline)
                    .font(.displayMedium)
                    .foregroundStyle(Color.deepInk)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, WPSpacing.sm)
            }

            Text(phaseSubtitle)
                .font(.bodySecondary)
                .foregroundStyle(Color.stone)
                .multilineTextAlignment(.center)
        }
    }

    private var stopOverline: String {
        let progress = coordinator.progress
        guard progress.totalStops > 0 else { return "TOUR" }
        return "STOP \(progress.currentStopNumber) OF \(progress.totalStops)"
    }

    private var idleHeadline: String {
        switch coordinator.phase {
        case .idle where coordinator.tourStatus == .completed: return "Tour complete"
        case .waitingForWaypoint: return "Walk to the next stop"
        case .playingTransition: return "Continue walking"
        default: return "Ready when you are"
        }
    }

    private var phaseSubtitle: String {
        switch coordinator.phase {
        case .idle where coordinator.tourStatus == .completed:
            return "Hope you enjoyed the walk."
        case .waitingForWaypoint:
            return "Audio begins automatically as you arrive."
        case .playingWaypoint:
            return coordinator.isPaused ? "Paused" : "Now playing"
        case .playingTransition:
            return "Ambient continues on the way."
        case .idle:
            return ""
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: WPSpacing.xl) {
            controlButton(systemName: "backward.fill", size: 22, action: coordinator.skipBackward)
                .accessibilityLabel("Skip backward")

            Button(action: togglePause) {
                ZStack {
                    Circle()
                        .fill(Color.terracotta)
                        .frame(width: 84, height: 84)
                    Image(systemName: coordinator.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(Color.warmPaper)
                        .offset(x: coordinator.isPaused ? 2 : 0) // optical centring for play glyph
                }
                .shadow(color: Color.terracotta.opacity(0.25), radius: 12, x: 0, y: 6)
            }
            .accessibilityLabel(coordinator.isPaused ? "Resume" : "Pause")

            controlButton(systemName: "forward.fill", size: 22, action: coordinator.skipForward)
                .accessibilityLabel("Skip forward")
        }
    }

    private func controlButton(systemName: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(Color.deepInk)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.parchment))
        }
    }

    private func togglePause() {
        if coordinator.isPaused { coordinator.resume() } else { coordinator.pause() }
    }

    // MARK: - Help I'm lost

    @ViewBuilder
    private var helpImLostButton: some View {
        if let next = coordinator.nextNavigationWaypoint {
            Button(action: { openMaps(to: next) }) {
                HStack(spacing: WPSpacing.xs) {
                    Image(systemName: "location.north.line.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Help, I'm lost")
                        .font(.bodyPrimary)
                }
                .foregroundStyle(Color.deepInk)
                .padding(.horizontal, WPSpacing.md)
                .padding(.vertical, WPSpacing.xs)
                .background(
                    Capsule().stroke(Color.deepInk.opacity(0.25), lineWidth: 1)
                )
            }
            .accessibilityLabel("Help, I'm lost. Open Apple Maps to \(next.title).")
        }
    }

    private func openMaps(to waypoint: Waypoint) {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
            latitude: waypoint.latitude,
            longitude: waypoint.longitude
        ))
        let item = MKMapItem(placemark: placemark)
        item.name = waypoint.title
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}
