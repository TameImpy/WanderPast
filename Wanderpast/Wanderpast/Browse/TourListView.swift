import SwiftUI
import WanderpastCore

/// Lists every published tour for a single city, with the editorial pick rendered as a hero card on top.
struct TourListView: View {
    @ObservedObject var viewModel: TourListViewModel
    let cityName: String
    let repository: CatalogueRepository

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WPSpacing.lg) {
                header
                content
            }
            .padding(.horizontal, WPSpacing.md)
            .padding(.vertical, WPSpacing.lg)
        }
        .background(Color.warmPaper)
        .navigationTitle(cityName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if case .loading = viewModel.state {
                viewModel.load()
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: WPSpacing.xxs) {
            Text("TOURS IN")
                .font(.overline)
                .tracking(2)
                .foregroundStyle(Color.terracotta)
            Text(cityName)
                .font(.displayLarge)
                .foregroundStyle(Color.deepInk)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            loadingView
        case .loaded(let pick, let others):
            loadedView(pick: pick, others: others)
        case .error(let retryable):
            errorView(retryable: retryable)
        }
    }

    private var loadingView: some View {
        VStack(spacing: WPSpacing.sm) {
            ProgressView()
                .tint(Color.terracotta)
            Text("LOADING")
                .font(.overline)
                .tracking(2)
                .foregroundStyle(Color.stone)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }

    @ViewBuilder
    private func loadedView(pick: Tour?, others: [Tour]) -> some View {
        LazyVStack(alignment: .leading, spacing: WPSpacing.lg) {
            if let pick {
                VStack(alignment: .leading, spacing: WPSpacing.xs) {
                    Text("FEATURED")
                        .font(.overline)
                        .tracking(2)
                        .foregroundStyle(Color.terracotta)
                    tourLink(for: pick) {
                        heroCard(pick)
                    }
                }
            }
            if !others.isEmpty {
                VStack(alignment: .leading, spacing: WPSpacing.sm) {
                    if pick != nil {
                        Text("MORE TOURS")
                            .font(.overline)
                            .tracking(2)
                            .foregroundStyle(Color.stone)
                            .padding(.top, WPSpacing.xs)
                    }
                    ForEach(others) { tour in
                        tourLink(for: tour) {
                            tourCard(tour)
                        }
                    }
                }
            }
            if pick == nil && others.isEmpty {
                emptyView
            }
        }
    }

    private func tourLink<Label: View>(for tour: Tour, @ViewBuilder label: () -> Label) -> some View {
        NavigationLink {
            TourDetailView(
                viewModel: TourDetailViewModel(tourID: tour.id, repository: repository)
            )
        } label: {
            label()
        }
        .buttonStyle(.plain)
    }

    private func heroCard(_ tour: Tour) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geo in
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
                    .frame(width: geo.size.width, height: 220)
                    .clipped()

                    LinearGradient(
                        colors: [Color.charcoal.opacity(0.0), Color.charcoal.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: geo.size.width, height: 220)

                    VStack(alignment: .leading, spacing: WPSpacing.xxs) {
                        Text(tour.era.uppercased())
                            .font(.overline)
                            .tracking(1.5)
                            .foregroundStyle(Color.sandstone)
                        Text(tour.title)
                            .font(.displayMedium)
                            .foregroundStyle(Color.warmPaper)
                    }
                    .padding(WPSpacing.sm)
                    .frame(width: geo.size.width, alignment: .leading)
                }
            }
            .frame(height: 220)

            VStack(alignment: .leading, spacing: WPSpacing.xxs) {
                Text(tour.description)
                    .font(.bodySecondary)
                    .foregroundStyle(Color.deepInk)
                    .lineSpacing(4)
                    .lineLimit(4)
                metadataLine(tour)
            }
            .padding(WPSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.parchment)
        .clipShape(RoundedRectangle(cornerRadius: WPRadius.lg))
    }

    private func tourCard(_ tour: Tour) -> some View {
        HStack(alignment: .top, spacing: WPSpacing.sm) {
            if let url = tour.heroImageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Color.charcoal
                    }
                }
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: WPRadius.sm))
            } else {
                Color.charcoal
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: WPRadius.sm))
            }

            VStack(alignment: .leading, spacing: WPSpacing.xxs) {
                Text(tour.era.uppercased())
                    .font(.overline)
                    .tracking(1.2)
                    .foregroundStyle(Color.terracotta)
                Text(tour.title)
                    .font(.displaySmall)
                    .foregroundStyle(Color.deepInk)
                    .lineLimit(2)
                metadataLine(tour)
            }
            Spacer(minLength: 0)
        }
        .padding(WPSpacing.sm)
        .background(Color.parchment)
        .clipShape(RoundedRectangle(cornerRadius: WPRadius.md))
    }

    private func metadataLine(_ tour: Tour) -> some View {
        HStack(spacing: WPSpacing.xs) {
            Text("\(tour.durationMinutes) MIN")
                .font(.monoSmall)
                .foregroundStyle(Color.stone)
            Text("·")
                .foregroundStyle(Color.stone)
            Text("\(tour.waypointCount) STOPS")
                .font(.monoSmall)
                .foregroundStyle(Color.stone)
            if tour.isFree {
                Text("·")
                    .foregroundStyle(Color.stone)
                Text("FREE")
                    .font(.monoSmall)
                    .foregroundStyle(Color.terracotta)
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: WPSpacing.sm) {
            Text("No tours yet")
                .font(.displaySmall)
                .foregroundStyle(Color.deepInk)
            Text("We're adding new walks for this city soon.")
                .font(.bodySecondary)
                .foregroundStyle(Color.stone)
                .multilineTextAlignment(.center)
        }
        .padding(WPSpacing.lg)
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private func errorView(retryable: Bool) -> some View {
        VStack(spacing: WPSpacing.sm) {
            Text(retryable ? "Couldn't load tours" : "Something went wrong")
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
        .frame(maxWidth: .infinity, minHeight: 240)
    }
}
