import Testing
import Foundation
@testable import WanderpastCore

@Suite("CatalogueParser")
struct CatalogueParserTests {

    @Test("Valid JSON parses into a Catalogue with the expected tour")
    func parsesValidJSON() throws {
        let json = """
        {
          "cities": [
            {
              "id": "london",
              "name": "London",
              "description": "Layered city.",
              "hero_image_url": null,
              "tour_count": 1,
              "editorial_pick_tour_id": "tower-prisoners",
              "general_accessibility_note": null
            }
          ],
          "tours": [
            {
              "id": "tower-prisoners",
              "title": "The Prisoners of the Tower",
              "city": "london",
              "theme": "Imprisonment",
              "era": "Medieval — Tudor",
              "era_start_year": 1100,
              "narration_style": "present_tense_omniscient",
              "narrator_name": "Eleanor Vane",
              "narrator_bio": "Historian.",
              "duration_minutes": 35,
              "waypoint_count": 1,
              "description": "Inside the walls.",
              "preview_clip_url": null,
              "ambient_soundscape_url": null,
              "completion_summary": "End.",
              "hero_image_url": null,
              "is_free": true,
              "price_tier": "free",
              "status": "published"
            }
          ],
          "waypoints": [
            {
              "id": "wp-01",
              "tour_id": "tower-prisoners",
              "order": 1,
              "title": "Traitors' Gate",
              "latitude": 51.5081,
              "longitude": -0.0761,
              "trigger_radius_m": 30.0,
              "audio_url": "https://example.com/wp01.mp3",
              "transition_audio_url": null
            }
          ]
        }
        """.data(using: .utf8)!

        let catalogue = try CatalogueParser.parse(data: json)

        #expect(catalogue.tours.count == 1)
        #expect(catalogue.tours.first?.title == "The Prisoners of the Tower")
        #expect(catalogue.tours.first?.eraStartYear == 1100)
    }

    @Test("Empty data throws CatalogueError.empty")
    func emptyDataThrowsEmpty() {
        #expect(throws: CatalogueError.empty) {
            try CatalogueParser.parse(data: Data())
        }
    }

    @Test("Malformed JSON throws CatalogueError.malformed")
    func malformedJSONThrowsMalformed() {
        let junk = "{ this is not json".data(using: .utf8)!
        #expect(throws: CatalogueError.malformed) {
            try CatalogueParser.parse(data: junk)
        }
    }

    @Test("Missing required field throws CatalogueError.invalid with field name")
    func missingFieldThrowsInvalid() {
        // Tour missing "title" — everything else is valid.
        let json = """
        {
          "cities": [],
          "tours": [
            {
              "id": "tower-prisoners",
              "city": "london",
              "theme": "Imprisonment",
              "era": "Medieval",
              "era_start_year": 1100,
              "narration_style": "present_tense_omniscient",
              "narrator_name": "Eleanor",
              "narrator_bio": "Historian.",
              "duration_minutes": 35,
              "waypoint_count": 0,
              "description": "...",
              "preview_clip_url": null,
              "ambient_soundscape_url": null,
              "completion_summary": "End.",
              "hero_image_url": null,
              "is_free": true,
              "price_tier": "free",
              "status": "published"
            }
          ],
          "waypoints": []
        }
        """.data(using: .utf8)!

        #expect(throws: CatalogueError.invalid(field: "title")) {
            try CatalogueParser.parse(data: json)
        }
    }
}
