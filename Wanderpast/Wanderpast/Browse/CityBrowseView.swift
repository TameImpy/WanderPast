import SwiftUI
import WanderpastCore

/// Top-level browse screen: lists UK towns and cities with published tours.
/// When location is granted, a "Near you" section surfaces tours nearest to the user.
struct CityBrowseView: View {
    @ObservedObject var viewModel: CityBrowseViewModel
    @ObservedObject var nearbyViewModel: NearbyToursViewModel
    @EnvironmentObject var completedTours: CompletedToursStore
    let repository: CatalogueRepository

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WPSpacing.lg) {
                header
                nearbySection
                content
            }
            .padding(.horizontal, WPSpacing.md)
            .padding(.vertical, WPSpacing.lg)
        }
        .background(Color.warmPaper)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(Color.charcoal)
                }
            }
        }
        .onAppear {
            if case .loading = viewModel.state {
                viewModel.load()
            }
            nearbyViewModel.start()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: WPSpacing.xxs) {
            Text("EXPLORE")
                .font(.overline)
                .tracking(2)
                .foregroundStyle(Color.terracotta)
            Text("Cities")
                .font(.displayLarge)
                .foregroundStyle(Color.deepInk)
        }
    }

    // MARK: - Near you

    @ViewBuilder
    private var nearbySection: some View {
        switch nearbyViewModel.state {
        case .hidden, .error:
            EmptyView()
        case .locating:
            nearbyHeader(subtitle: "Finding tours near you…")
        case .loaded(let nearby) where nearby.isEmpty:
            nearbyHeader(subtitle: "No tours within reach. Browse cities below.")
        case .loaded(let nearby):
            VStack(alignment: .leading, spacing: WPSpacing.sm) {
                nearbyHeader(subtitle: "Tours closest to your current location")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: WPSpacing.sm) {
                        ForEach(nearby, id: \.tour.id) { item in
                            NavigationLink {
                                TourDetailView(
                                    viewModel: TourDetailViewModel(
                                        tourID: item.tour.id,
                                        repository: repository
                                    )
                                )
                            } label: {
                                nearbyCard(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func nearbyHeader(subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: WPSpacing.xxs) {
            Text("NEAR YOU")
                .font(.overline)
                .tracking(2)
                .foregroundStyle(Color.terracotta)
            Text(subtitle)
                .font(.bodySecondary)
                .foregroundStyle(Color.stone)
        }
    }

    private func nearbyCard(_ item: NearbyTour) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let url = item.tour.heroImageURL {
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
                .frame(width: 220, height: 140)
                .clipped()

                LinearGradient(
                    colors: [Color.charcoal.opacity(0.0), Color.charcoal.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: 220, height: 140)

                Text(distanceLabel(item.distanceMeters))
                    .font(.overline)
                    .tracking(1.5)
                    .foregroundStyle(Color.warmPaper)
                    .padding(.horizontal, WPSpacing.xs)
                    .padding(.vertical, WPSpacing.xxxs)
                    .background(Color.terracotta)
                    .clipShape(Capsule())
                    .padding(WPSpacing.xs)

                if completedTours.isCompleted(tourID: item.tour.id) {
                    CompletedBadge()
                        .padding(WPSpacing.xs)
                        .frame(width: 220, height: 140, alignment: .topTrailing)
                }
            }

            VStack(alignment: .leading, spacing: WPSpacing.xxxs) {
                Text(item.tour.title)
                    .font(.displaySmall)
                    .foregroundStyle(Color.deepInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(item.tour.era.uppercased())
                    .font(.overline)
                    .tracking(1.5)
                    .foregroundStyle(Color.stone)
            }
            .padding(WPSpacing.sm)
            .frame(width: 220, alignment: .leading)
        }
        .background(Color.parchment)
        .clipShape(RoundedRectangle(cornerRadius: WPRadius.lg))
    }

    private func distanceLabel(_ meters: Double) -> String {
        if meters < 1000 {
            return "STARTS \(Int(meters.rounded())) M AWAY"
        }
        let km = meters / 1000
        if km < 10 {
            return String(format: "STARTS %.1f KM AWAY", km)
        }
        return "STARTS \(Int(km.rounded())) KM AWAY"
    }

    // MARK: - Cities

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            loadingView
        case .loaded(let rows):
            list(of: rows)
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

    private func list(of rows: [CityRow]) -> some View {
        LazyVStack(spacing: WPSpacing.md) {
            ForEach(rows) { row in
                NavigationLink {
                    TourListView(
                        viewModel: TourListViewModel(cityID: row.id, repository: repository),
                        cityName: row.name,
                        repository: repository
                    )
                } label: {
                    cityCard(row)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func cityCard(_ row: CityRow) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .bottomLeading) {
                    Group {
                        if let url = row.heroImageURL {
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
                    .frame(width: geo.size.width, height: 180)
                    .clipped()

                    LinearGradient(
                        colors: [Color.charcoal.opacity(0.0), Color.charcoal.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: geo.size.width, height: 180)

                    VStack(alignment: .leading, spacing: WPSpacing.xxxs) {
                        Text(row.name)
                            .font(.displayMedium)
                            .foregroundStyle(Color.warmPaper)
                        Text(tourCountLabel(row.publishedTourCount))
                            .font(.overline)
                            .tracking(1.5)
                            .foregroundStyle(Color.sandstone)
                    }
                    .padding(WPSpacing.sm)
                    .frame(width: geo.size.width, alignment: .leading)
                }
            }
            .frame(height: 180)

            Text(row.description)
                .font(.bodySecondary)
                .foregroundStyle(Color.deepInk)
                .lineSpacing(4)
                .padding(WPSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.parchment)
        .clipShape(RoundedRectangle(cornerRadius: WPRadius.lg))
    }

    private func tourCountLabel(_ count: Int) -> String {
        count == 1 ? "1 TOUR" : "\(count) TOURS"
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
