import Foundation

public struct City: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let heroImageURL: URL?
    public let tourCount: Int
    public let editorialPickTourID: String?
    public let generalAccessibilityNote: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case heroImageURL = "hero_image_url"
        case tourCount = "tour_count"
        case editorialPickTourID = "editorial_pick_tour_id"
        case generalAccessibilityNote = "general_accessibility_note"
    }
}
