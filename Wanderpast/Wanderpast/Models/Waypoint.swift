import Foundation

/// A single GPS-triggered stop within a tour cluster.
struct Waypoint: Codable, Identifiable {
    let id: String
    let tourID: String
    let order: Int
    let title: String
    let latitude: Double
    let longitude: Double
    let triggerRadiusM: Double
    let audioURL: URL
    let transitionAudioURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case tourID = "tour_id"
        case order, title, latitude, longitude
        case triggerRadiusM = "trigger_radius_m"
        case audioURL = "audio_url"
        case transitionAudioURL = "transition_audio_url"
    }
}
