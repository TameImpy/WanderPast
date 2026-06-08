import SwiftUI
import WanderpastCore

/// Post-tour keepsake. Shown over `InTourView` when `TourService.tourStatus == .completed`.
/// Renders a stylised path through the waypoints walked plus an editorial completion summary.
struct CompletionCardView: View {
    let tour: Tour
    let waypoints: [Waypoint]
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.deepInk.opacity(0.55).ignoresSafeArea()

            VStack(spacing: WPSpacing.md) {
                Text("TOUR COMPLETE")
                    .font(.overline)
                    .tracking(2.5)
                    .foregroundStyle(Color.terracotta)

                Text(tour.title)
                    .font(.displayLarge)
                    .foregroundStyle(Color.deepInk)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                ClusterPathView(waypoints: waypoints)
                    .frame(height: 160)
                    .padding(.horizontal, WPSpacing.lg)
                    .padding(.vertical, WPSpacing.sm)

                Text(tour.completionSummary)
                    .font(.bodyPrimary)
                    .foregroundStyle(Color.charcoal)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, WPSpacing.sm)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onDone) {
                    Text("Done")
                        .font(.bodyPrimary.weight(.medium))
                        .foregroundStyle(Color.warmPaper)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, WPSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: WPRadius.md, style: .continuous)
                                .fill(Color.deepInk)
                        )
                }
                .padding(.top, WPSpacing.xs)
            }
            .padding(WPSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: WPRadius.xl, style: .continuous)
                    .fill(Color.warmPaper)
            )
            .padding(.horizontal, WPSpacing.md)
            .shadow(color: Color.deepInk.opacity(0.25), radius: 24, x: 0, y: 12)
        }
    }
}

/// Stylised path through the walked waypoints, normalised into the available
/// drawing area so the shape of the route is visible regardless of scale.
private struct ClusterPathView: View {
    let waypoints: [Waypoint]

    var body: some View {
        GeometryReader { geo in
            let points = normalisedPoints(in: geo.size)
            ZStack {
                // Background paper tint
                RoundedRectangle(cornerRadius: WPRadius.lg, style: .continuous)
                    .fill(Color.parchment)

                // Connecting line
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for p in points.dropFirst() { path.addLine(to: p) }
                }
                .stroke(
                    Color.terracotta.opacity(0.6),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round, dash: [4, 4])
                )

                // Waypoint dots
                ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                    Circle()
                        .fill(Color.deepInk)
                        .frame(width: 10, height: 10)
                        .position(p)
                }
            }
        }
    }

    /// Project waypoint lat/long into the drawing rectangle, preserving the
    /// shape of the cluster. Falls back to a horizontal line if all points
    /// share a coordinate (defensive against single-waypoint tours).
    private func normalisedPoints(in size: CGSize) -> [CGPoint] {
        guard !waypoints.isEmpty else { return [] }
        let lats = waypoints.map(\.latitude)
        let lons = waypoints.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return [] }

        let inset: CGFloat = 24
        let drawable = CGRect(
            x: inset,
            y: inset,
            width: max(size.width - inset * 2, 1),
            height: max(size.height - inset * 2, 1)
        )

        let latRange = maxLat - minLat
        let lonRange = maxLon - minLon

        return waypoints.map { wp in
            let normX: CGFloat
            let normY: CGFloat
            if lonRange > 0 {
                normX = CGFloat((wp.longitude - minLon) / lonRange)
            } else {
                normX = 0.5
            }
            if latRange > 0 {
                // Flip Y so north is up.
                normY = 1 - CGFloat((wp.latitude - minLat) / latRange)
            } else {
                normY = 0.5
            }
            return CGPoint(
                x: drawable.minX + normX * drawable.width,
                y: drawable.minY + normY * drawable.height
            )
        }
    }
}
