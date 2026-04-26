import SwiftUI

/// Displays the sample tour metadata styled with Wanderpast design tokens.
struct TourDetailView: View {
    private let content = SampleData.load()

    private var tour: Tour { content.tours[0] }
    private var city: City { content.cities[0] }
    private var waypoints: [Waypoint] { content.waypoints.sorted { $0.order < $1.order } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: - Hero area
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(Color.charcoal)
                        .frame(height: 280)

                    VStack(alignment: .leading, spacing: WPSpacing.xxs) {
                        Text(tour.era.uppercased())
                            .font(.overline)
                            .tracking(1.5)
                            .foregroundStyle(Color.sandstone)

                        Text(tour.title)
                            .font(.displayLarge)
                            .foregroundStyle(Color.warmPaper)
                    }
                    .padding(WPSpacing.md)
                }

                // MARK: - Metadata strip
                VStack(spacing: 0) {
                    HStack(spacing: WPSpacing.md) {
                        metadataPill(label: "DURATION", value: "\(tour.durationMinutes) min")
                        metadataPill(label: "WAYPOINTS", value: "\(tour.waypointCount)")
                        metadataPill(label: "STYLE", value: narrationLabel)
                    }
                    .padding(.horizontal, WPSpacing.md)
                    .padding(.vertical, WPSpacing.sm)
                }
                .background(Color.deepInk)

                // MARK: - Body content
                VStack(alignment: .leading, spacing: WPSpacing.lg) {

                    // City + theme
                    HStack(spacing: WPSpacing.xxs) {
                        Text(city.name.uppercased())
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

                    // Description
                    Text(tour.description)
                        .font(.bodyPrimary)
                        .foregroundStyle(Color.deepInk)
                        .lineSpacing(6)

                    // Free badge
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

                    Divider()
                        .background(Color.sandstone)

                    // Narrator
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

                    Divider()
                        .background(Color.sandstone)

                    // Waypoints list
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
                .padding(WPSpacing.md)
            }
        }
        .background(Color.warmPaper)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Helpers

    private var narrationLabel: String {
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
}

#Preview {
    TourDetailView()
}
