import SwiftUI

// MARK: - Font families
// Wanderpast uses three typefaces:
//   Fraunces  — display / serif headings
//   Inter     — body / sans-serif
//   JetBrains Mono — overlines, metadata, small labels
//
// Custom font files can be added to the bundle and registered in
// Info.plist under UIAppFonts. Until then, we fall back to system
// serif / sans-serif / monospaced equivalents that approximate the feel.

extension Font {

    // MARK: - Display (Fraunces or serif fallback)

    /// Large display title — tour name on detail screen.
    static let displayLarge = Font.custom("Fraunces", size: 32, relativeTo: .largeTitle)
        .weight(.semibold)

    /// Medium display — section headings.
    static let displayMedium = Font.custom("Fraunces", size: 24, relativeTo: .title)
        .weight(.medium)

    /// Small display — card titles, waypoint names.
    static let displaySmall = Font.custom("Fraunces", size: 20, relativeTo: .title3)
        .weight(.medium)

    // MARK: - Body (Inter or sans fallback)

    /// Primary body text.
    static let bodyPrimary = Font.custom("Inter", size: 16, relativeTo: .body)

    /// Secondary body text — descriptions, bios.
    static let bodySecondary = Font.custom("Inter", size: 14, relativeTo: .subheadline)

    /// Caption text.
    static let caption = Font.custom("Inter", size: 12, relativeTo: .caption)

    // MARK: - Mono (JetBrains Mono or mono fallback)

    /// Overline labels — era, theme, metadata.
    static let overline = Font.custom("JetBrainsMono-Regular", size: 11, relativeTo: .caption2)

    /// Mono small — timestamps, coordinates.
    static let monoSmall = Font.custom("JetBrainsMono-Regular", size: 10, relativeTo: .caption2)
}

// MARK: - Fallback helpers
// When custom fonts are not yet bundled, SwiftUI's .custom() gracefully
// falls back to the system default. These convenience modifiers apply
// the closest system design equivalents.

extension View {
    /// Apply serif styling (used when Fraunces is not available).
    func serifFallback() -> some View {
        self.font(.system(.title, design: .serif))
    }
}
