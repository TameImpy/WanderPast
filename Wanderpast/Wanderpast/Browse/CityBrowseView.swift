import SwiftUI
import WanderpastCore

/// Top-level browse screen: lists UK towns and cities with published tours.
struct CityBrowseView: View {
    @ObservedObject var viewModel: CityBrowseViewModel
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
        .onAppear {
            if case .loading = viewModel.state {
                viewModel.load()
            }
        }
    }

    // MARK: - Sections

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
