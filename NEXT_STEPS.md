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
- **Issue #6** (Tour catalogue) — backend slices 0–6 done and Slice 7 (CityBrowseViewModel + CityBrowseView) done. 65 tests in 10 suites covering parser, queries (incl. cityRows), cache policy, fetcher, cache, repository, and CityBrowseState mapping. UI slices 8–10 remaining (see below).
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

### Done (backend slices 0–6 + UI slice 7, all tests passing)
- Codable models relocated to `WanderpastCore` and made public (`Tour`, `City`, `Waypoint`, `Catalogue`). `eraStartYear: Int` added to `Tour` for chronological sorting. `sample_tour.json` updated.
- `CatalogueParser` — `parse(data:) throws -> Catalogue` with typed errors `.empty`, `.malformed`, `.invalid(field:)`
- Query API on `Catalogue` — `publishedCities()`, `cityRows()` (rows with derived published-tour count), `tours(in:)` with editorial pick first, `toursGroupedByEra()` sorted by `eraStartYear`, `tour(id:)`, `waypoints(for:)`, `editorialPick(for:)`
- `CachePolicy` state machine — 1-hour TTL, decisions: `useCache | refetchAndUseFresh | refetchInBackgroundButShowCache | showError`
- `CatalogueFetcher` — URLSession wrapper with typed errors `.notFound`, `.networkUnavailable`, `.timeout`, `.unexpectedResponse`
- `CatalogueCache` — FileManager wrapper, save/load/lastFetchDate
- `CatalogueRepository` — keystone: `loadCatalogue() -> AsyncStream<LoadResult>`. Yields `.fresh(Catalogue) | .cached(Catalogue, isStale:) | .failure(CatalogueLoadError)`. Stream may yield cached then fresh when stale + online. Parse failure preserves prior cache.
- **Slice 7 — CityBrowseViewModel + CityBrowseView**
  - `CityRow` + `Catalogue.cityRows()` in Core (3 tests): one row per city with at least one published tour, order preserved, count derived from catalogue rather than the static field
  - `CityBrowseState` pure enum + `CityBrowseState.from(loadResult:)` mapper in Core (5 tests): `.fresh`/`.cached` → `.loaded`, `.offline`/`.fetchFailed` → `.error(retryable: true)`, `.parseFailed` → `.error(retryable: false)`
  - `CityBrowseViewModel` ObservableObject (main app) — `@MainActor`, consumes the repo stream into `@Published state`, cancels prior load on retry
  - `CityBrowseView` SwiftUI screen — `EXPLORE / Cities` header, city cards with hero image + tour count overlay, loading and error states with Retry button

### Remaining (UI slices 8–10)

#### Pre-slice TODO — publish `catalogue.json`
Slice 10 assumes a hosted catalogue.json. Before Slice 10 (ideally during Slice 8 so Slice 9 can also point at it) we need to:
- Create `Wanderpast/Resources/catalogue.json` by extending `sample_tour.json` to the `{ cities, tours, waypoints }` shape that `CatalogueParser` expects. London should remain present (so the existing Tower tour keeps working), but add at least one extra city + one extra tour so `CityBrowseView` and `TourListView` aren't trivially single-item.
- Commit it to the repo so it's reachable at `https://raw.githubusercontent.com/TameImpy/WanderPast/main/Wanderpast/Resources/catalogue.json`.
- Bundle it as well so the first launch has something to parse even before any network call (Slice 10 will decide whether to seed the cache from the bundle or just rely on the fetcher).

#### Slice 8 — Tour list per city + theme browse
Pure logic in `WanderpastCore` (TDD, follow the Slice 7 pattern):
- `TourListState` enum: `.loading | .loaded(editorialPick: Tour?, others: [Tour]) | .error(retryable:)`. Editorial pick is exposed separately so the UI can render a hero card. `others` must exclude the pick to avoid double-rendering. Pure `from(loadResult:cityID:)` mapper.
- `ThemeBrowseState` enum: `.loading | .loaded([EraGroup]) | .error(retryable:)`. Pure `from(loadResult:)` mapper that delegates to `Catalogue.toursGroupedByEra()` (already exists).
- Tests cover: editorial pick is excluded from `others`; city with no pick puts everything in `others`; same error mapping rules as `CityBrowseState`.

Main app (`Wanderpast/Browse/`):
- `TourListViewModel(cityID:repository:)` — `@MainActor` ObservableObject, same `load()`/`retry()` pattern as `CityBrowseViewModel`.
- `ThemeBrowseViewModel(repository:)` — same shape.
- `TourListView(viewModel:)` SwiftUI screen — header with city name; if `editorialPick` non-nil, render a "Featured" hero card; below it a `LazyVStack` of regular tour cards. Loading and retryable error states.
- `ThemeBrowseView(viewModel:)` SwiftUI screen — list of era sections (era label + start year overline, then tour cards).

Navigation wiring:
- Make `CityBrowseView`'s city card a `NavigationLink` (or set a `selectedCity` binding that drives `.navigationDestination`) pushing `TourListView(cityID:)`. Repository is passed through the environment or constructor.
- Don't wire ThemeBrowse into the main flow yet — it's a sibling entry point we'll surface later. Just make sure it compiles and previews.

Project plumbing:
- Update `project.pbxproj` to register the new files (uses traditional file references; folders are not auto-synchronized — see how Slice 7 added `Browse/`).

#### Slice 9 — Real `TourDetailView` driven by the catalogue
Pure logic in `WanderpastCore`:
- `TourDetailState` enum: `.loading | .loaded(Tour, [Waypoint]) | .error(retryable:) | .notFound`. Pure mapper takes `LoadResult + tourID` and returns `.notFound` when the catalogue parses but doesn't contain that ID.
- Tests cover all five branches.

Main app:
- `TourDetailViewModel(tourID:repository:)` — `@MainActor` ObservableObject.
- Upgrade existing `Wanderpast/TourDetailView.swift` to take a `TourDetailViewModel` instead of constructing `SampleData` directly. Keep the existing styling — most of it is reusable — but data-source it from the loaded `Tour` and `[Waypoint]`.
- Add new UI elements:
  - **Hero image** — replace the flat `Color.charcoal` band with `AsyncImage(url: tour.heroImageURL)` falling back to charcoal.
  - **Static MapKit overview** — `Map(...)` with a `MKCoordinateRegion` computed from the bounding box of waypoint coords (add small padding). Read-only, no annotations beyond a marker per waypoint. Lives below the description.
  - **PreviewClipButton** — new view in `Wanderpast/Browse/` or `Wanderpast/Tour/`. Tapping plays a 60-second clip via a new `AudioEngine.playPreviewClip(url:)` (separate AVPlayer instance so it doesn't tangle with `startTour`). Disabled when `tour.previewClipURL` is nil.
- `SampleData` becomes dev-only; can be deleted in Slice 10 if not used.

Project plumbing:
- Add the new Swift files to `project.pbxproj`.
- Add `MapKit.framework` (or use SwiftUI's `Map` which auto-links it — verify after first build).

#### Slice 10 — Boot the app into browse + end-to-end QA
- Construct a real `CatalogueRepository` at app start. Cache directory = `FileManager.default.urls(for: .documentDirectory, ...).first!.appendingPathComponent("catalogue")`. URL = the GitHub raw URL committed in the pre-slice TODO.
- Replace `WanderpastApp`'s root view: `NavigationStack { CityBrowseView(viewModel: CityBrowseViewModel(repository: ...)) }`. The repository instance should be created once and passed into child VMs.
- App-wide loading/error: the per-screen states already cover this; just make sure `TourCoordinator` (used by `InTourView`) still receives the right `Tour` and `[Waypoint]` when `Start Tour` is pressed — currently it reads from `SampleData`; rewire it to take the data from the `TourDetailViewModel`.
- Manual QA checklist:
  - Airplane mode, cold cache → error state with Retry, retry once back online recovers.
  - Online → cities list renders, tap city → tour list with editorial pick first, tap tour → detail with hero, map, preview button.
  - Preview button plays a 60-second clip and stops automatically.
  - Start Tour still works end-to-end and audio plays via `InTourView`.
  - Returning to the same city within 1 hour uses cache (no network spinner); after the cache TTL, fresh fetch happens.

### Decisions locked in
- CDN URL: `https://raw.githubusercontent.com/TameImpy/WanderPast/main/Wanderpast/Resources/catalogue.json` (created during Slice 8 pre-slice TODO)
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
│   │   ├── CatalogueRepository.swift     # Composes fetch + cache + parse + policy (6 tests)
│   │   └── CityBrowseState.swift         # Pure mapper LoadResult → browse state (5 tests)
│   └── Tests/WanderpastCoreTests/        # 65 tests total in 10 suites
├── Wanderpast/                           # Main iOS app
│   ├── Audio/AudioEngine.swift           # AVFoundation wrapper
│   ├── Location/LiveGeofenceManager.swift  # CoreLocation wrapper
│   ├── Tour/
│   │   ├── TourCoordinator.swift         # ObservableObject bridge to SwiftUI
│   │   └── InTourView.swift              # In-tour UI
│   ├── Browse/
│   │   ├── CityBrowseViewModel.swift     # ObservableObject — wraps CatalogueRepository
│   │   └── CityBrowseView.swift          # SwiftUI screen — list of city cards
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
