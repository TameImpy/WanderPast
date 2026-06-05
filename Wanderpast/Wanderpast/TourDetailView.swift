import SwiftUI
import MapKit
import WanderpastCore

/// Displays a tour's metadata, hero image, map overview, preview clip, and "Start Tour" action.
/// Data-sourced from a `TourDetailViewModel` (catalogue-driven). The `TourCoordinator` is still
/// responsible for the in-tour audio session when Start Tour is pressed.
struct TourDetailView: View {
    @ObservedObject var viewModel: TourDetailViewModel
    @EnvironmentObject var coordinator: TourCoordinator
    @State private var showingTour = false

    var body: some View {
        ScrollView {
            switch viewModel.state {
            case .loading:
                loadingView
            case .loaded(let tour, let waypoints):
                loadedContent(tour: tour, waypoints: waypoints)
            case .error(let retryable):
                errorView(retryable: retryable)
            case .notFound:
                notFoundView
            }
        }
        .background(Color.warmPaper)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            if case .loading = viewModel.state {
                viewModel.load()
            }
        }
        .navigationDestination(isPresented: $showingTour) {
            InTourView()
                .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Loaded content

    @ViewBuilder
    private func loadedContent(tour: Tour, waypoints: [Waypoint]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            heroBanner(tour)
            metadataStrip(tour)
            bodyContent(tour: tour, waypoints: waypoints)
        }
    }

    private func heroBanner(_ tour: Tour) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let url = tour.heroImageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Color.charcoal
                        }
                    }
                } else {
                    Color.charcoal
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 320)
            .clipped()

            LinearGradient(
                colors: [Color.charcoal.opacity(0.0), Color.charcoal.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity)
            .frame(height: 320)

            VStack(alignment: .leading, spacing: WPSpacing.xxs) {
                Text(tour.era.uppercased())
                    .font(.overline)
                    .tracking(1.5)
                    .foregroundStyle(Color.sandstone)

                Text(tour.title)
                    .font(.displayLarge)
                    .foregroundStyle(Color.warmPaper)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(WPSpacing.md)
        }
        .frame(maxWidth: .infinity)
    }

    private func metadataStrip(_ tour: Tour) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: WPSpacing.md) {
                metadataPill(label: "DURATION", value: "\(tour.durationMinutes) min")
                metadataPill(label: "WAYPOINTS", value: "\(tour.waypointCount)")
                metadataPill(label: "STYLE", value: narrationLabel(tour))
            }
            .padding(.horizontal, WPSpacing.md)
            .padding(.vertical, WPSpacing.sm)
        }
        .background(Color.deepInk)
    }

    @ViewBuilder
    private func bodyContent(tour: Tour, waypoints: [Waypoint]) -> some View {
        VStack(alignment: .leading, spacing: WPSpacing.lg) {

            HStack(spacing: WPSpacing.xxs) {
                Text(tour.city.uppercased())
                    .font(.overline)
                    .tracking(1.2)
                    .foregroundStyle(Color.terracotta)
                Text("  /  ")
                    .font(.overline)
                    .foregroundStyle(Color.stone)
                Text(tour.theme.uppercased())
                    .font(.overline)
                    .tracking(1.2)
                    .foregroundStyle(Color.stone)
            }

            Text(tour.description)
                .font(.bodyPrimary)
                .foregroundStyle(Color.deepInk)
                .lineSpacing(6)

            PreviewClipButton(url: tour.previewClipURL, audioEngine: coordinator.audioEngine)

            Button(action: {
                coordinator.startTour(tour: tour, waypoints: waypoints)
                showingTour = true
            }) {
                Text("START TOUR")
                    .font(.overline)
                    .tracking(2)
                    .foregroundStyle(Color.warmPaper)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, WPSpacing.sm)
                    .background(Color.terracotta)
                    .clipShape(RoundedRectangle(cornerRadius: WPRadius.sm))
            }

            if tour.isFree {
                Text("FREE TOUR")
                    .font(.overline)
                    .tracking(2)
                    .foregroundStyle(Color.warmPaper)
                    .padding(.horizontal, WPSpacing.xs)
                    .padding(.vertical, WPSpacing.xxxs)
                    .background(Color.terracotta)
                    .clipShape(RoundedRectangle(cornerRadius: WPRadius.sm))
            }

            mapSection(waypoints: waypoints)

            Divider().background(Color.sandstone)

            narratorSection(tour)

            Divider().background(Color.sandstone)

            waypointsSection(waypoints)
        }
        .padding(WPSpacing.md)
    }

    // MARK: - Subsections

    @ViewBuilder
    private func mapSection(waypoints: [Waypoint]) -> some View {
        if !waypoints.isEmpty, let region = boundingRegion(for: waypoints) {
            VStack(alignment: .leading, spacing: WPSpacing.xs) {
                Text("ROUTE")
                    .font(.overline)
                    .tracking(1.5)
                    .foregroundStyle(Color.stone)

                Map(initialPosition: .region(region), interactionModes: []) {
                    ForEach(waypoints) { wp in
                        Marker(wp.title, coordinate: CLLocationCoordinate2D(
                            latitude: wp.latitude,
                            longitude: wp.longitude
                        ))
                        .tint(Color.terracotta)
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: WPRadius.lg))
            }
        }
    }

    private func narratorSection(_ tour: Tour) -> some View {
        VStack(alignment: .leading, spacing: WPSpacing.xxs) {
            Text("NARRATED BY")
                .font(.overline)
                .tracking(1.5)
                .foregroundStyle(Color.stone)

            Text(tour.narratorName)
                .font(.displaySmall)
                .foregroundStyle(Color.deepInk)

            Text(tour.narratorBio)
                .font(.bodySecondary)
                .foregroundStyle(Color.stone)
                .lineSpacing(4)
        }
    }

    private func waypointsSection(_ waypoints: [Waypoint]) -> some View {
        VStack(alignment: .leading, spacing: WPSpacing.sm) {
            Text("WAYPOINTS")
                .font(.overline)
                .tracking(1.5)
                .foregroundStyle(Color.stone)

            ForEach(waypoints) { wp in
                HStack(alignment: .top, spacing: WPSpacing.sm) {
                    Text("\(wp.order)")
                        .font(.monoSmall)
                        .foregroundStyle(Color.terracotta)
                        .frame(width: 20, alignment: .trailing)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(wp.title)
                            .font(.bodyPrimary)
                            .foregroundStyle(Color.deepInk)

                        Text("\(wp.latitude, specifier: "%.4f"), \(wp.longitude, specifier: "%.4f")")
                            .font(.monoSmall)
                            .foregroundStyle(Color.stone)
                    }
                }
                .padding(.vertical, WPSpacing.xxs)
            }
        }
    }

    // MARK: - Non-loaded states

    private var loadingView: some View {
        VStack(spacing: WPSpacing.sm) {
            ProgressView().tint(Color.terracotta)
            Text("LOADING TOUR")
                .font(.overline)
                .tracking(2)
                .foregroundStyle(Color.stone)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    private func errorView(retryable: Bool) -> some View {
        VStack(spacing: WPSpacing.sm) {
            Text(retryable ? "Couldn't load this tour" : "Something went wrong")
                .font(.displaySmall)
                .foregroundStyle(Color.deepInk)
            Text(retryable
                 ? "Check your connection and try again."
                 : "We're looking into it. Please try again later.")
                .font(.bodySecondary)
                .foregroundStyle(Color.stone)
                .multilineTextAlignment(.center)

            if retryable {
                Button(action: { viewModel.retry() }) {
                    Text("RETRY")
                        .font(.overline)
                        .tracking(2)
                        .foregroundStyle(Color.warmPaper)
                        .padding(.horizontal, WPSpacing.md)
                        .padding(.vertical, WPSpacing.xs)
                        .background(Color.terracotta)
                        .clipShape(RoundedRectangle(cornerRadius: WPRadius.sm))
                }
                .padding(.top, WPSpacing.xs)
            }
        }
        .padding(WPSpacing.lg)
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    private var notFoundView: some View {
        VStack(spacing: WPSpacing.sm) {
            Text("Tour not found")
                .font(.displaySmall)
                .foregroundStyle(Color.deepInk)
            Text("This tour may have been removed from the catalogue.")
                .font(.bodySecondary)
                .foregroundStyle(Color.stone)
                .multilineTextAlignment(.center)
        }
        .padding(WPSpacing.lg)
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    // MARK: - Helpers

    private func narrationLabel(_ tour: Tour) -> String {
        switch tour.narrationStyle {
        case .presentTenseOmniscient: return "Omniscient"
        case .characterLedFirstPerson: return "First person"
        case .expertLed: return "Expert-led"
        }
    }

    private func metadataPill(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.monoSmall)
                .tracking(1)
                .foregroundStyle(Color.stone)
            Text(value)
                .font(.bodySecondary)
                .foregroundStyle(Color.warmPaper)
        }
        .frame(maxWidth: .infinity)
    }

    /// Smallest MKCoordinateRegion that contains every waypoint, padded so markers aren't
    /// flush against the edge of the map.
    private func boundingRegion(for waypoints: [Waypoint]) -> MKCoordinateRegion? {
        guard let first = waypoints.first else { return nil }
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for wp in waypoints {
            minLat = min(minLat, wp.latitude)
            maxLat = max(maxLat, wp.latitude)
            minLon = min(minLon, wp.longitude)
            maxLon = max(maxLon, wp.longitude)
        }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let latPadding = max((maxLat - minLat) * 1.6, 0.005)
        let lonPadding = max((maxLon - minLon) * 1.6, 0.005)
        let span = MKCoordinateSpan(latitudeDelta: latPadding, longitudeDelta: lonPadding)
        return MKCoordinateRegion(center: center, span: span)
    }
}
