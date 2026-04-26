import Foundation

/// Aggregated content payload matching the CDN JSON structure.
struct TourContent: Codable {
    let cities: [City]
    let tours: [Tour]
    let waypoints: [Waypoint]
}

/// Loads and decodes the bundled sample tour JSON.
enum SampleData {
    static func load() -> TourContent {
        guard let url = Bundle.main.url(forResource: "sample_tour", withExtension: "json") else {
            fatalError("Missing sample_tour.json in bundle")
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(TourContent.self, from: data)
        } catch {
            fatalError("Failed to decode sample_tour.json: \(error)")
        }
    }
}
