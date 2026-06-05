import SwiftUI
import WanderpastCore

/// Lists tours grouped by era, sorted chronologically. Used as a sibling entry point to CityBrowseView.
struct ThemeBrowseView: View {
    @ObservedObject var viewModel: ThemeBrowseViewModel

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

    private var header: some View {
        VStack(alignment: .leading, spacing: WPSpacing.xxs) {
            Text("BROWSE BY")
                .font(.overline)
                .tracking(2)
                .foregroundStyle(Color.terracotta)
            Text("Era")
                .font(.displayLarge)
                .foregroundStyle(Color.deepInk)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            loadingView
        case .loaded(let groups):
            list(of: groups)
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

    private func list(of groups: [EraGroup]) -> some View {
        LazyVStack(alignment: .leading, spacing: WPSpacing.xl) {
            ForEach(groups, id: \.era) { group in
                VStack(alignment: .leading, spacing: WPSpacing.sm) {
                    HStack(alignment: .firstTextBaseline, spacing: WPSpacing.xs) {
                        Text(group.era)
                            .font(.displaySmall)
                            .foregroundStyle(Color.deepInk)
                        Text("FROM \(group.eraStartYear)")
                            .font(.monoSmall)
                            .tracking(1)
                            .foregroundStyle(Color.stone)
                    }
                    ForEach(group.tours) { tour in
                        tourCard(tour)
                    }
                }
            }
        }
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
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: WPRadius.sm))
            } else {
                Color.charcoal
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: WPRadius.sm))
            }

            VStack(alignment: .leading, spacing: WPSpacing.xxs) {
                Text(tour.city.uppercased())
                    .font(.overline)
                    .tracking(1.2)
                    .foregroundStyle(Color.terracotta)
                Text(tour.title)
                    .font(.bodyPrimary)
                    .foregroundStyle(Color.deepInk)
                    .lineLimit(2)
                Text("\(tour.durationMinutes) MIN · \(tour.waypointCount) STOPS")
                    .font(.monoSmall)
                    .foregroundStyle(Color.stone)
            }
            Spacer(minLength: 0)
        }
        .padding(WPSpacing.sm)
        .background(Color.parchment)
        .clipShape(RoundedRectangle(cornerRadius: WPRadius.md))
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
