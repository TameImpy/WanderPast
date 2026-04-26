import SwiftUI

/// Spacing and radius constants for the Wanderpast design system.
/// Generous whitespace is a core brand principle — prefer larger values.
enum WPSpacing {
    /// 4pt — hairline gaps, icon padding.
    static let xxxs: CGFloat = 4

    /// 8pt — tight inner padding.
    static let xxs: CGFloat = 8

    /// 12pt — compact element spacing.
    static let xs: CGFloat = 12

    /// 16pt — standard inner padding.
    static let sm: CGFloat = 16

    /// 24pt — card padding, section gaps.
    static let md: CGFloat = 24

    /// 32pt — generous section spacing.
    static let lg: CGFloat = 32

    /// 48pt — major section dividers.
    static let xl: CGFloat = 48

    /// 64pt — top-level screen padding.
    static let xxl: CGFloat = 64
}

enum WPRadius {
    /// 4pt — subtle rounding on small elements.
    static let sm: CGFloat = 4

    /// 8pt — buttons, input fields.
    static let md: CGFloat = 8

    /// 12pt — cards.
    static let lg: CGFloat = 12

    /// 16pt — modal sheets, large cards.
    static let xl: CGFloat = 16

    /// Fully rounded (pill shape).
    static let full: CGFloat = 999
}
