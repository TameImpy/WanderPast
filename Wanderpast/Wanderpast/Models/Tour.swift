import Foundation

/// A focused, cluster-based audio history tour tied to a single theme or moment.
struct Tour: Codable, Identifiable {
    let id: String
    let title: String
    let city: String
    let theme: String
    let era: String
    let narrationStyle: NarrationStyle
    let narratorName: String
    let narratorBio: String
    let durationMinutes: Int
    let waypointCount: Int
    let description: String
    let previewClipURL: URL?
    let ambientSoundscapeURL: URL?
    let completionSummary: String
    let heroImageURL: URL?
    let isFree: Bool
    let priceTier: PriceTier
    let status: TourStatus

    enum CodingKeys: String, CodingKey {
        case id, title, city, theme, era
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

enum NarrationStyle: String, Codable {
    case presentTenseOmniscient = "present_tense_omniscient"
    case characterLedFirstPerson = "character_led_first_person"
    case expertLed = "expert_led"
}

enum PriceTier: String, Codable {
    case free
    case single   // £1.99
    case bundle   // £7.99 city bundle
}

enum TourStatus: String, Codable {
    case draft
    case published
    case archived
}
