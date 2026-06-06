import SwiftUI

/// Small "COMPLETED" pill rendered on tour cards once the user has finished a tour.
/// Lives in the Tour module because completion is owned by `CompletedToursStore`.
struct CompletedBadge: View {
    var body: some View {
        HStack(spacing: WPSpacing.xxxs) {
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .bold))
            Text("COMPLETED")
                .font(.overline)
                .tracking(1.5)
        }
        .foregroundStyle(Color.warmPaper)
        .padding(.horizontal, WPSpacing.xs)
        .padding(.vertical, WPSpacing.xxxs)
        .background(Color.deepInk)
        .clipShape(Capsule())
    }
}
