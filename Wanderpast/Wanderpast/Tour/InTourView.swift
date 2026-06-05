import SwiftUI

/// Minimal in-tour UI: current waypoint, progress, play/pause, skip controls.
struct InTourView: View {
    @EnvironmentObject var coordinator: TourCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundStyle(Color.stone)
                        .padding(WPSpacing.sm)
                }
                Spacer()
            }

            Spacer()

            // Current state
            VStack(spacing: WPSpacing.sm) {
                Text(phaseLabel.uppercased())
                    .font(.overline)
                    .tracking(1.5)
                    .foregroundStyle(Color.stone)

                if let title = coordinator.currentWaypointTitle {
                    Text(title)
                        .font(.displaySmall)
                        .foregroundStyle(Color.deepInk)
                        .multilineTextAlignment(.center)
                }

                // Progress
                Text("\(coordinator.completedCount) of \(coordinator.totalWaypoints) waypoints")
                    .font(.bodySecondary)
                    .foregroundStyle(Color.stone)
            }
            .padding(.horizontal, WPSpacing.lg)

            Spacer()

            // Controls
            HStack(spacing: WPSpacing.xl) {
                Button(action: { coordinator.skipBackward() }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundStyle(Color.deepInk)
                }

                Button(action: {
                    if coordinator.isPaused {
                        coordinator.resume()
                    } else {
                        coordinator.pause()
                    }
                }) {
                    Image(systemName: coordinator.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.terracotta)
                }

                Button(action: { coordinator.skipForward() }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundStyle(Color.deepInk)
                }
            }
            .padding(.bottom, WPSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmPaper)
    }

    private var phaseLabel: String {
        switch coordinator.phase {
        case .idle: return "Tour complete"
        case .waitingForWaypoint: return "Walk to next waypoint"
        case .playingWaypoint: return "Now playing"
        case .playingTransition: return "Next stop"
        }
    }
}
