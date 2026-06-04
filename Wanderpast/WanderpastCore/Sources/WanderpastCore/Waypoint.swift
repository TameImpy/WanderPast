import Foundation

public struct Waypoint: Codable, Identifiable, Sendable {
    public let id: String
    public let tourID: String
    public let order: Int
    public let title: String
    public let latitude: Double
    public let longitude: Double
    public let triggerRadiusM: Double
    public let audioURL: URL
    public let transitionAudioURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case tourID = "tour_id"
        case order, title, latitude, longitude
        case triggerRadiusM = "trigger_radius_m"
        case audioURL = "audio_url"
        case transitionAudioURL = "transition_audio_url"
    }
}
