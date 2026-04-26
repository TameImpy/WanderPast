import SwiftUI

/// Branded launch screen displayed on app startup.
struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Color.deepInk
                .ignoresSafeArea()

            VStack(spacing: WPSpacing.sm) {
                Text("Wanderpast")
                    .font(.displayLarge)
                    .foregroundStyle(Color.warmPaper)

                Text("BY HISTORYEXTRA")
                    .font(.overline)
                    .tracking(3)
                    .foregroundStyle(Color.stone)
            }
        }
    }
}

#Preview {
    LaunchScreen()
}
