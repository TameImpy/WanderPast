import Foundation
import WanderpastCore

/// Loads and decodes the bundled sample tour JSON.
enum SampleData {
    static func load() -> Catalogue {
        guard let url = Bundle.main.url(forResource: "sample_tour", withExtension: "json") else {
            fatalError("Missing sample_tour.json in bundle")
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(Catalogue.self, from: data)
        } catch {
            fatalError("Failed to decode sample_tour.json: \(error)")
        }
    }
}
