import SwiftUI

// MARK: - Font families
// Wanderpast uses three typefaces:
//   Fraunces  — display / serif headings
//   Inter     — body / sans-serif
//   JetBrains Mono — overlines, metadata, small labels

extension Font {

    // MARK: - Display (Fraunces)

    /// Large display title — tour name on detail screen.
    static let displayLarge = Font.custom("Fraunces-SemiBold", size: 32, relativeTo: .largeTitle)

    /// Medium display — section headings.
    static let displayMedium = Font.custom("Fraunces-Medium", size: 24, relativeTo: .title)

    /// Small display — card titles, waypoint names.
    static let displaySmall = Font.custom("Fraunces-Medium", size: 20, relativeTo: .title3)

    // MARK: - Body (Inter)

    /// Primary body text.
    static let bodyPrimary = Font.custom("Inter-Regular", size: 16, relativeTo: .body)

    /// Secondary body text — descriptions, bios.
    static let bodySecondary = Font.custom("Inter-Regular", size: 14, relativeTo: .subheadline)

    /// Caption text.
    static let caption = Font.custom("Inter-Regular", size: 12, relativeTo: .caption)

    // MARK: - Mono (JetBrains Mono)

    /// Overline labels — era, theme, metadata.
    static let overline = Font.custom("JetBrainsMono-Regular", size: 11, relativeTo: .caption2)

    /// Mono small — timestamps, coordinates.
    static let monoSmall = Font.custom("JetBrainsMono-Regular", size: 10, relativeTo: .caption2)
}
