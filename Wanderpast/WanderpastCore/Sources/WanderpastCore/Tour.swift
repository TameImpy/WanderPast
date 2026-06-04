import Foundation

public struct Tour: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let city: String
    public let theme: String
    public let era: String
    public let eraStartYear: Int
    public let narrationStyle: NarrationStyle
    public let narratorName: String
    public let narratorBio: String
    public let durationMinutes: Int
    public let waypointCount: Int
    public let description: String
    public let previewClipURL: URL?
    public let ambientSoundscapeURL: URL?
    public let completionSummary: String
    public let heroImageURL: URL?
    public let isFree: Bool
    public let priceTier: PriceTier
    public let status: TourContentStatus

    enum CodingKeys: String, CodingKey {
        case id, title, city, theme, era
        case eraStartYear = "era_start_year"
        case narrationStyle = "narration_style"
        case narratorName = "narrator_name"
        case narratorBio = "narrator_bio"
        case durationMinutes = "duration_minutes"
        case waypointCount = "waypoint_count"
        case description
        case previewClipURL = "preview_clip_url"
        case ambientSoundscapeURL = "ambient_soundscape_url"
        case completionSummary = "completion_summary"
        case heroImageURL = "hero_image_url"
        case isFree = "is_free"
        case priceTier = "price_tier"
        case status
    }
}

public enum NarrationStyle: String, Codable, Sendable {
    case presentTenseOmniscient = "present_tense_omniscient"
    case characterLedFirstPerson = "character_led_first_person"
    case expertLed = "expert_led"
}

public enum PriceTier: String, Codable, Sendable {
    case free
    case single
    case bundle
}

public enum TourContentStatus: String, Codable, Sendable {
    case draft
    case published
    case archived
}
