import Foundation

/// A city that hosts one or more Wanderpast tours.
struct City: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let heroImageURL: URL?
    let tourCount: Int
    let editorialPickTourID: String?
    let generalAccessibilityNote: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case heroImageURL = "hero_image_url"
        case tourCount = "tour_count"
        case editorialPickTourID = "editorial_pick_tour_id"
        case generalAccessibilityNote = "general_accessibility_note"
    }
}
