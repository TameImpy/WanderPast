# Wanderpast — Next Steps

---

## Completed

- Product discovery: 31-question grilling, all major decisions finalised
- `architecture.md` — single source of truth for what we're building
- `deferred_decisions.md` — what's explicitly out of MVP scope
- `CLAUDE.md` — project instructions for future sessions
- PRD submitted as GitHub issue #1 (https://github.com/TameImpy/WanderPast/issues/1)
- 15 implementation issues created (#2-#16) as vertical slices
- **Issue #2** (Xcode project skeleton) — done
- **Issue #3** (AudioEngine) — done. `AudioEngineState` pure state machine with 10 tests
- **Issue #4** (GeofenceManager) — done. `GeofenceState` pure state machine with 8 tests
- **Issue #5** (Tracer Bullet) — partially done (see below)
- **Issue #6** (Tour catalogue) — backend slices 0–6 done. 32 new tests covering parser, queries, cache policy, fetcher, cache, repository. UI slices 7–10 remaining (see below).
- Design system: colours, spacing, typography tokens all implemented
- Fonts bundled: Fraunces (display/serif), Inter (body/sans), JetBrains Mono (overlines/metadata)
- Placeholder audio: medieval ambient soundscape (Freesound.org), TTS narration for 3 waypoints

---

## Issue #5 — what's done vs what's remaining

### Done
- `TourService` state machine (7 tests, orchestrates AudioEngine + GeofenceManager)
- `AudioEngine` — AVFoundation wrapper with dual-channel playback, lock screen controls, interruption handling
- `LiveGeofenceManager` — CoreLocation wrapper with geofence registration
- `TourCoordinator` — ObservableObject bridging pure logic to SwiftUI, with UserDefaults persistence (currently disabled)
- `InTourView` — minimal in-tour UI: play/pause, skip forward/backward, waypoint indicator, close button
- `TourDetailView` — "Start Tour" button navigates to InTourView
- GPX simulation file for Tower of London walk (`Resources/TowerOfLondonWalk.gpx`)
- Skip forward works from idle state (triggers first waypoint)
- 25 total unit tests across 3 suites, all passing

### Remaining for Issue #5
- [ ] **Geofence triggering** — not working in simulator. CoreLocation `didEnterRegion` doesn't fire reliably. Needs real device testing or a dev-mode "simulate geofence entry" button
- [ ] **Skip backward from idle** — tapping skip backward when no waypoint is playing does nothing. Same fix pattern as skip forward (trigger last waypoint or no-op)
- [ ] **Checkpoint resume** — temporarily disabled (`TourCoordinator.swift` lines 170-177). Needs a "restart tour" button so completed tours can be replayed. Currently every app launch starts fresh
- [ ] **Background audio** — Info.plist has `audio` background mode but not tested with screen locked
- [ ] **Lock screen media controls** — MPNowPlayingInfoCenter is wired up but not tested
- [ ] **Transition audio between waypoints** — the flow exists in the state machine but needs testing end-to-end

---

## Known bugs / tech debt

| Issue | Detail | File(s) |
|-------|--------|---------|
| Simulator audio errors | `HALC_ProxyObjectMap::_CreateSystemObject: there is no system object` — intermittent simulator issue, not a code bug. Fix: erase simulator content and settings | N/A |
| Simulator geofences unreliable | `didEnterRegion` doesn't fire when setting custom location. GPX simulation menu was greyed out in Xcode | `LiveGeofenceManager.swift` |
| Checkpoint causes stale state | After completing tour, reopening app shows "3 of 3" with no way to restart. Save/load commented out as workaround | `TourCoordinator.swift` |
| TourContentStatus rename | Renamed `TourStatus` → `TourContentStatus` in `Tour.swift` to avoid collision with WanderpastCore's `TourStatus`. Slightly awkward naming | `Models/Tour.swift` |

---

## Issue #6 — what's done vs what's remaining

### Done (backend slices 0–6, all tests passing)
- Codable models relocated to `WanderpastCore` and made public (`Tour`, `City`, `Waypoint`, `Catalogue`). `eraStartYear: Int` added to `Tour` for chronological sorting. `sample_tour.json` updated.
- `CatalogueParser` — `parse(data:) throws -> Catalogue` with typed errors `.empty`, `.malformed`, `.invalid(field:)`
- Query API on `Catalogue` — `publishedCities()`, `tours(in:)` with editorial pick first, `toursGroupedByEra()` sorted by `eraStartYear`, `tour(id:)`, `waypoints(for:)`, `editorialPick(for:)`
- `CachePolicy` state machine — 1-hour TTL, decisions: `useCache | refetchAndUseFresh | refetchInBackgroundButShowCache | showError`
- `CatalogueFetcher` — URLSession wrapper with typed errors `.notFound`, `.networkUnavailable`, `.timeout`, `.unexpectedResponse`
- `CatalogueCache` — FileManager wrapper, save/load/lastFetchDate
- `CatalogueRepository` — keystone: `loadCatalogue() -> AsyncStream<LoadResult>`. Yields `.fresh(Catalogue) | .cached(Catalogue, isStale:) | .failure(CatalogueLoadError)`. Stream may yield cached then fresh when stale + online. Parse failure preserves prior cache.

### Remaining (UI slices 7–10)
- [ ] **Slice 7** — `CityBrowseViewModel` (ObservableObject, wraps repository) + `CityBrowseView` SwiftUI screen. State: `.loading | .loaded([CityRow]) | .error(retryable:)`.
- [ ] **Slice 8** — `TourListViewModel(cityID:)` (editorial pick first, flagged) and `ThemeBrowseViewModel` (groups by era). SwiftUI screens.
- [ ] **Slice 9** — `TourDetailViewModel(tourID:)`. Upgrade `TourDetailView` with narrator block, hero image, static MapKit overview map (computes region from waypoint coords), 60-second `PreviewClipButton` (calls `AudioEngine.playPreviewClip(url:)`).
- [ ] **Slice 10** — Boot `WanderpastApp` into `CityBrowseView`. App-wide error/loading states. Manual verification: airplane mode → error state, online → cities → tours → detail with map + preview, Start Tour still works.

### Decisions locked in
- CDN URL for testing: GitHub raw URL (`raw.githubusercontent.com/...`), to be set up when we wire repo into app
- Cache TTL: 1 hour
- Era ordering: `eraStartYear: Int` field on Tour (added)

## Remaining GitHub issues (in priority order)

### Core experience (do these next)
- **Issue #7** — Proximity-based discovery: nearby tours
- **Issue #11** — In-tour UX: controls, Help I'm lost, and completion card

### Auth & commerce
- **Issue #8** — Sign in with Apple + user state persistence
- **Issue #9** — IAP: individual tour purchase
- **Issue #10** — IAP: city bundles and annual pass

### Analytics & feedback
- **Issue #13** — Firebase Analytics: 7 core events
- **Issue #14** — TestFlight post-tour survey

### Content
- **Issue #12** — Wishlist: save tours for future trips
- **Issue #15** — AI-produced Tower of London tour (ElevenLabs TTS, Claude/GPT scripts)
- **Issue #16** — Sample content: 2-3 human-produced London tours (HITL — requires editorial)

### Deferred (post-MVP)
See `deferred_decisions.md` for full list. Key items:
- Android build
- Offline download
- Gift purchases
- Full interactive map
- Immediate ID integration
- Multi-language narration
- User-generated content

---

## Project structure

```
Wanderpast/
├── WanderpastCore/                       # Swift Package — pure testable logic
│   ├── Sources/WanderpastCore/
│   │   ├── AudioEngineState.swift        # Audio state machine (10 tests)
│   │   ├── GeofenceState.swift           # GPS state machine (8 tests)
│   │   ├── TourService.swift             # Orchestrator state machine (7 tests)
│   │   ├── Tour.swift                    # Codable Tour + NarrationStyle/PriceTier/TourContentStatus
│   │   ├── City.swift                    # Codable City
│   │   ├── Waypoint.swift                # Codable Waypoint
│   │   ├── Catalogue.swift               # Top-level { cities, tours, waypoints }
│   │   ├── CatalogueParser.swift         # parse(data:) + typed errors (4 tests)
│   │   ├── CatalogueQueries.swift        # publishedCities, tours(in:), grouped by era, etc. (8 tests)
│   │   ├── CachePolicy.swift             # State machine for cache decisions (5 tests)
│   │   ├── CatalogueFetcher.swift        # URLSession wrapper (4 tests)
│   │   ├── CatalogueCache.swift          # FileManager wrapper (3 tests)
│   │   └── CatalogueRepository.swift     # Composes fetch + cache + parse + policy (6 tests)
│   └── Tests/WanderpastCoreTests/        # 57 tests total
├── Wanderpast/                           # Main iOS app
│   ├── Audio/AudioEngine.swift           # AVFoundation wrapper
│   ├── Location/LiveGeofenceManager.swift  # CoreLocation wrapper
│   ├── Tour/
│   │   ├── TourCoordinator.swift         # ObservableObject bridge to SwiftUI
│   │   └── InTourView.swift              # In-tour UI
│   ├── Models/SampleData.swift           # Bundle.main loader for sample_tour.json
│   ├── DesignSystem/                     # Color, Typography, Spacing tokens
│   ├── Resources/
│   │   ├── Audio/                        # Bundled .m4a audio files
│   │   ├── Fonts/                        # Fraunces, Inter, JetBrains Mono
│   │   ├── sample_tour.json              # Hardcoded Tower of London tour
│   │   └── TowerOfLondonWalk.gpx         # GPS simulation file
│   ├── TourDetailView.swift              # Tour detail + "Start Tour"
│   ├── WanderpastApp.swift               # App entry point
│   └── Info.plist                        # Background modes, fonts, location strings
```

## Running the project

1. Open `Wanderpast/Wanderpast.xcodeproj` in Xcode
2. Select iPhone simulator, press Cmd + R
3. Tap "Start Tour", then use skip forward to hear narration
4. If simulator audio errors appear, do Device → Erase All Content and Settings and re-run

## Running tests

```bash
cd Wanderpast/WanderpastCore && swift test
```

## GitHub
- Repo: https://github.com/TameImpy/WanderPast
- PRD: Issue #1
- Implementation issues: #2 (done) through #16

## Critical rule
**Always use the TDD skill for implementation.** Tests first, then code. No exceptions.
