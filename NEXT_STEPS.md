# Wanderpast — Next Steps

---

## Completed

- Product discovery: 31-question grilling, all major decisions finalised
- `architecture.md` — single source of truth for what we're building
- `deferred_decisions.md` — what's explicitly out of MVP scope
- `CLAUDE.md` — project instructions for future sessions
- PRD submitted as GitHub issue #1 (https://github.com/TameImpy/WanderPast/issues/1)
- 15 implementation issues created (#2-#16) as vertical slices
- **Issue #2** (Xcode project skeleton) — done, closed on GitHub.
- **Issue #3** (AudioEngine) — done, closed on GitHub. `AudioEngineState` pure state machine with 10 tests.
- **Issue #4** (GeofenceManager) — done, closed on GitHub. `GeofenceState` pure state machine with 8 tests.
- **Issue #5** (Tracer Bullet) — done end-to-end, closed on GitHub with deferred items noted in the close comment. Tower of London tour plays through `InTourView` in the simulator. Known follow-ups still tracked in this file's "Issue #5 — remaining" section below.
- **Issue #6** (Tour catalogue) — done, closed on GitHub. Eleven slices: backend 0–6 (parser, queries, cache policy, fetcher, cache, repository), Slice 7 (CityBrowseView), Slice 8 (TourListView + ThemeBrowseView), Slice 9 (catalogue-driven TourDetailView with hero, MapKit, preview clip), and Slice 10 (CityBrowseView as the app root, end-to-end navigation, `TourCoordinator.startTour(tour:waypoints:)` driven by the loaded data instead of `SampleData`). 83 tests in 13 suites. Hero-image horizontal-overflow bug fixed in `67b7950` (use `GeometryReader` to hard-cap width — `.frame(maxWidth: .infinity)` alone is a request, not a cap, and the layout broke for any Unsplash crop whose intrinsic width exceeded the viewport).
- **Issue #7** (Proximity-based discovery) — done, QA'd against real-device location on 2026-06-06. Four slices: Slice 1 (`Coordinate`, `NearbyTour`, `Catalogue.nearbyTours(from:within:)` with haversine — 7 tests), Slice 2 (`LocationAuthorization`, `NearbyToursState.from(authorization:userLocation:loadResult:radiusMeters:)` — 8 tests), Slice 3 (`LiveLocationProvider` CoreLocation wrapper, `NearbyToursViewModel` ObservableObject combining repo + location), Slice 4 ("Near you" horizontal-scroll section in `CityBrowseView` with distance overlays on tour cards, hidden when location denied or section empty). 98 tests in 15 suites across `WanderpastCore`. Info.plist `NSLocationWhenInUseUsageDescription` updated to mention discovery. Ready to close on GitHub.
- **Issue #8** (Sign in with Apple + user state persistence) — implementation complete pending end-to-end QA with a real Apple ID. Six pure-logic slices in `WanderpastCore`: `AccountIdentity` + `AccountState` enum (3 tests); `RemoteUserPayload` Codable wire format with snake_case keys, ISO8601 dates, sparse-tolerant decode (2 tests); `RemoteUserPayload.merging(local:remote:)` unioning completed tour IDs and owned product IDs and taking max `updated_at` (2 tests); `UserSyncState` state machine — `idle | syncing | synced(at:) | failed(retryable:)` with begin/succeeded/failed events, network and server failures retryable, auth not (6 tests); `BackendUserClient` protocol + `InMemoryBackendUserClient` actor stub so the app wires end-to-end without AWS (2 tests); `AccountSyncOrchestrator.sync(stableID:local:backend:now:)` doing fetch → merge → upsert (2 tests). Plus `CompletedTours.allIDs` for sync payloads (1 test). Framework layer in main app: `AppleSignInController` (ASAuthorizationAppleIDProvider async wrapper), `AccountStore` ObservableObject (persists `AccountIdentity` in UserDefaults under `wanderpast.account.identity.v1`, drives sign-in/out, syncs on tour completion via Combine subscription to `CompletedToursStore.$tours`), `SettingsView` (SignInWithAppleButton, account info, Sync now, Sign out, sync status footer). UI entry: gear-person icon in `CityBrowseView` toolbar. `WanderpastApp` constructs `AccountStore(backend: InMemoryBackendUserClient())` and attaches it to `CompletedToursStore`. `Wanderpast.entitlements` adds `com.apple.developer.applesignin = Default` and `CODE_SIGN_ENTITLEMENTS` is wired in both Debug and Release. 137 tests in 25 suites across `WanderpastCore`, all passing. iOS build succeeds. Remaining: (1) enable the "Sign in with Apple" capability for the App ID in the Apple Developer portal so the entitlement provisions; (2) end-to-end QA — tap gear → Sign in with Apple sheet, complete sign-in, complete a tour, verify it appears in the in-memory backend, sign out, sign back in, confirm the completion is restored; (3) replace `InMemoryBackendUserClient` with a real Lambda+DynamoDB-backed `BackendUserClient` (separate follow-up — Issue #8 closes once the stub-backed end-to-end flow is QA'd, real backend can land alongside #9/#10 IAP work).

- **Issue #11** (In-tour UX) — implementation complete and visual QA passed end-to-end on 2026-06-08 (Tower of London tour played through, completion card rendered correctly with cluster path + completion summary, COMPLETED badge appeared on FEATURED hero + MORE TOURS row + "Near you" card, Help-I'm-lost handed off to Apple Maps, badge persisted across `⌘ .` kill-and-relaunch from the simulator home screen). Closed on GitHub. Title-wrap polish fix shipped in b9b07aa (added `.fixedSize(horizontal: false, vertical: true)` to the title `Text` in `CompletionCardView.swift` — visually verified with "The Prisoners of the Tower" wrapping cleanly to two lines on the completion card). Seven slices: Slice A (`TourProgress` + `TourService.progress` for "Stop N of M" — 4 tests), Slice B (`TourService.nextNavigationWaypointID` for the Help-I'm-lost target — 5 tests), Slice C (Codable `CompletedTours` value type — 4 tests), Slice D (`CompletedToursStore` ObservableObject persisting via UserDefaults under `wanderpast.completedTours.v1`; `TourCoordinator.attach(completedToursStore:)` and auto-mark on `tourStatus == .completed`; `WanderpastApp` owns the store and injects it as `EnvironmentObject`), Slice E (redesigned `InTourView` with warm-paper background, Fraunces overline + stop title, 84pt terracotta play/pause with shadow + parchment skip pills, and a "Help, I'm lost" capsule button that fires `MKMapItem.openInMaps(launchOptions:)` with walking directions to `coordinator.nextNavigationWaypoint`), Slice F (`CompletionCardView` overlay with a `ClusterPathView` that normalises waypoint lat/long onto a dashed terracotta path inside a parchment tile, displays `tour.completionSummary`, and dismisses `InTourView` via "Done"), Slice G (reusable `CompletedBadge` rendered on the `TourListView` FEATURED hero, the MORE TOURS row, and the `CityBrowseView` "Near you" cards). 111 tests in 18 suites across `WanderpastCore`. iOS build succeeds. Remaining: in-simulator visual QA of the in-tour screen, Help I'm lost handoff, completion card, and badge after a completed tour (`xcrun simctl` can't drive taps inside the app).
- Design system: colours, spacing, typography tokens all implemented
- Fonts bundled: Fraunces (display/serif), Inter (body/sans), JetBrains Mono (overlines/metadata)
- Placeholder audio: medieval ambient soundscape (Freesound.org), TTS narration for 3 waypoints

---

## Issue #5 — remaining follow-ups (closed on GitHub, tracked here for the next session)

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

### Done (backend slices 0–6 + UI slices 7–10, all tests passing)
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
- **Pre-slice TODO — `catalogue.json` published**
  - `Wanderpast/Resources/catalogue.json` created and committed with London (2 published tours) + York (1 published tour) + 10 waypoints. Served at the GitHub raw URL Slice 10 will consume.
- **Slice 8 — TourListView + ThemeBrowseView**
  - `TourListState` pure enum + `TourListState.from(loadResult:cityID:)` mapper in Core (7 tests): editorial pick exposed separately and excluded from `others`; city-with-no-pick puts everything in `others`; unknown cityID yields empty `.loaded`; error mapping mirrors `CityBrowseState`.
  - `ThemeBrowseState` pure enum + `ThemeBrowseState.from(loadResult:)` mapper in Core (5 tests): delegates to `Catalogue.toursGroupedByEra()`; same error mapping.
  - `TourListViewModel(cityID:repository:)` and `ThemeBrowseViewModel(repository:)` ObservableObjects (main app) — `@MainActor`, consume the repo stream, cancel prior load on retry.
  - `TourListView(viewModel:cityName:)` SwiftUI screen — `TOURS IN / <City>` header, FEATURED hero card for the editorial pick (full-bleed image + era + title overlay + description + metadata), MORE TOURS list of compact cards with thumbnail.
  - `ThemeBrowseView(viewModel:)` SwiftUI screen — `BROWSE BY / Era` header, era sections with start year overline + tour cards. Not wired into the main flow yet — sibling entry point for later.
  - `CityBrowseView` city card wrapped in `NavigationLink` to `TourListView(cityID:)`; `CityBrowseView` now also takes a `repository:` parameter so it can construct child VMs.
- **Slice 9 — Catalogue-driven TourDetailView**
  - `TourDetailState` pure enum + `TourDetailState.from(loadResult:tourID:)` mapper in Core (6 tests): `.loaded(Tour, [Waypoint])` for fresh/cached when present; `.notFound` (distinct from `.error`) when catalogue parses but doesn't contain the tour; standard retryable/non-retryable error mapping for the failure cases.
  - `TourDetailViewModel(tourID:repository:)` ObservableObject (main app) — same `@MainActor` load/retry pattern as the other VMs.
  - `TourDetailView` rewritten to take a `TourDetailViewModel + TourCoordinator`. Switches on `state`: loading / loaded / error(retryable:) / notFound. Loaded UI keeps the existing styling but data-sources from the published `Tour` and `[Waypoint]`, and adds three new things:
    - **Hero image** — `AsyncImage(url: tour.heroImageURL)` over the title banner, falling back to charcoal.
    - **MapKit route overview** — `Map(initialPosition:)` zoomed to the bounding box of waypoint coordinates (with padding so markers aren't flush against the edge), tinted markers, no interaction.
    - **PreviewClipButton** — pill that toggles between PLAY 60-SEC PREVIEW and STOP PREVIEW. Disabled when the catalogue entry has no `preview_clip_url`. Backed by a new `AudioEngine.playPreviewClip(url:)` using a separate AVPlayer that streams from the CDN and auto-stops at 60s, fully isolated from the tour audio path.
  - `WanderpastApp` constructs a real `CatalogueRepository` at launch (FileManager-backed `CatalogueCache`, default `CatalogueFetcher`, GitHub raw URL) and boots into `TourDetailView` for `tower-of-london-prisoners`. `TourCoordinator.startTour()` is unchanged — Slice 10 will rewire it to take Tour + Waypoint data from the view model.
- **Slice 10 — End-to-end browse → detail → tour**
  - `WanderpastApp` root is now `NavigationStack { CityBrowseView(viewModel: ..., repository: ...) }`. The `CatalogueRepository` is created once in `init` and passed into child VMs; the shared `TourCoordinator` is injected via `.environmentObject(...)` and read by `TourDetailView` and `InTourView` via `@EnvironmentObject` (their explicit `coordinator:` arguments are gone).
  - `TourListView` got a `repository:` parameter and wraps the FEATURED hero card + MORE TOURS cards in `NavigationLink`s pushing `TourDetailView` with a fresh `TourDetailViewModel(tourID:repository:)`. `CityBrowseView` now passes the repository through to `TourListView`.
  - `TourCoordinator.startTour()` is now `startTour(tour: Tour, waypoints: [Waypoint])`. `TourDetailView`'s Start Tour button hands the loaded `Tour` + `[Waypoint]` from `TourDetailViewModel.state` directly to the coordinator — no more `SampleData.load()` round-trip. `SampleData.swift` deleted (dead code); `sample_tour.json` stays bundled in case we want a no-network fallback later.

### Remaining — end-to-end QA only

Manual QA checklist (then Issue #6 closes):
- Airplane mode, cold cache → error state with Retry; retry once back online recovers.
- Online → cities list renders (London, York), tap city → tour list with editorial pick first, tap tour → detail with hero, map, preview button.
- Preview button plays a 60-second clip and stops automatically. *(Catalogue preview URLs are placeholders — clip won't actually stream until real CDN content lands. Button toggling works; audio will be silent.)*
- Start Tour still works end-to-end for the Tower of London tour (uses bundled audio) and `InTourView` plays. Blitz/York will navigate fine but have no bundled audio yet — that's expected and tracked in Issues #15/#16.
- Returning to the same city within 1 hour uses cache (no network spinner); after the cache TTL, fresh fetch happens.

### Decisions locked in
- CDN URL: `https://raw.githubusercontent.com/TameImpy/WanderPast/main/Wanderpast/Resources/catalogue.json` (created during Slice 8 pre-slice TODO)
- Cache TTL: 1 hour
- Era ordering: `eraStartYear: Int` field on Tour (added)

## Remaining GitHub issues (in priority order)

### Suggested next pickup
**Issue #9** (IAP: individual tour purchase) is the recommended next ticket now that #8 is implementation-complete behind a stubbed backend. The pure-logic shape of #9 (Codable purchase records → backend client → owned-products merge) mirrors what we just did for #8 and can re-use `BackendUserClient` + `AccountSyncOrchestrator`. Both Issue #8 and Issue #11 still need end-to-end QA before closing on GitHub — see the QA checklists below.

### Issue #8 — QA checklist (before closing on GitHub)
- [x] Apple Developer Program enrolment active (paid 2026-06-07, approved 2026-06-08). Team ID `68X5UNNLZ5` upgraded in place from Personal Team — no project changes needed.
- [x] `app.wanderpast.Wanderpast` App ID registered in the developer portal with the **Sign In with Apple** capability ticked as a primary App ID. Provisioning profile refreshed; Xcode shows `Sign in with Apple` in the target's Capabilities with no error. App builds and runs on the iPhone 17 Pro simulator.
- [ ] **Sign simulator into an Apple ID** — blocked on 2026-06-08 by a 1-hour Apple ID password reset cooldown. Once the new password is active, sign the simulator in via Settings → "Sign in to your iPhone".
- [ ] Launch app, tap the person icon top-right of the cities screen → Settings → "Sign in with Apple". Complete the Apple sheet (Touch ID via `⌘ ⌥ M` if needed). Verify the account name/email appears in Settings.
- [ ] Complete a tour (Tower of London) while signed in. Verify the "Synced at HH:MM" footer appears in Settings.
- [ ] Tap **Sign out**. Tap **Sign in with Apple** again. Verify the completed tour still shows the COMPLETED badge on the FEATURED hero / MORE TOURS card (state restored from `InMemoryBackendUserClient`).
- [ ] Confirm free tours remain accessible without signing in (browse, start, play through a tour with `state == .signedOut`).
- [ ] **Real backend (separate follow-up — Issue #8 closes once stub-backed flow is QA'd):** swap `InMemoryBackendUserClient` in `WanderpastApp.init` for a Lambda+DynamoDB-backed client. The `BackendUserClient` protocol is in place; no other Swift code should need to change. Bundle this work with Issues #9/#10 (IAP) since they reuse the same backend client pattern.

### Issue #11 — QA checklist (before closing on GitHub)
- [ ] Launch app, tap London → Tower of London tour → Start Tour. Verify `InTourView` shows warm-paper background, "STOP 1 OF 3" overline, large terracotta play/pause button, parchment skip pills.
- [ ] Tap "Help, I'm lost" — Apple Maps should open with walking directions to the next waypoint (e.g. Traitors' Gate, then Beauchamp Tower after first stop is reached).
- [ ] Skip forward through all 3 waypoints. After the final transition completes, the completion card overlay should appear with the stylised cluster path + completion summary. Tap Done to dismiss.
- [ ] Return to TourListView for London — Tower of London tour should now show a "COMPLETED" pill badge on both the FEATURED hero and the MORE TOURS card (also on the "Near you" card on the cities screen if location is granted).
- [ ] Kill and relaunch the app — completion marker should still be present (UserDefaults persistence).

### Core experience

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
│   │   ├── CityBrowseState.swift         # Pure mapper LoadResult → browse state (5 tests)
│   │   ├── TourListState.swift           # Pure mapper LoadResult + cityID → tour-list state (7 tests)
│   │   ├── ThemeBrowseState.swift        # Pure mapper LoadResult → theme-browse state (5 tests)
│   │   ├── TourDetailState.swift         # Pure mapper LoadResult + tourID → detail state (6 tests)
│   │   ├── Proximity.swift               # Coordinate, NearbyTour, Catalogue.nearbyTours(from:within:) — haversine (7 tests)
│   │   ├── NearbyToursState.swift        # LocationAuthorization + pure mapper auth + location + LoadResult → state (8 tests)
│   │   ├── TourProgress.swift            # "Stop N of M" value type + TourService.progress (4 tests)
│   │   ├── CompletedTours.swift          # Codable set of finished tour IDs (5 tests)
│   │   ├── AccountState.swift            # AccountIdentity + AccountState enum (3 tests)
│   │   ├── RemoteUserPayload.swift       # snake_case Codable wire format + merge policy (4 tests)
│   │   ├── UserSyncState.swift           # sync state machine + UserSyncEvent / UserSyncFailure (6 tests)
│   │   ├── BackendUserClient.swift       # Protocol + InMemoryBackendUserClient actor stub (2 tests)
│   │   └── AccountSyncOrchestrator.swift # Pure sync orchestration (2 tests)
│   └── Tests/WanderpastCoreTests/        # 137 tests total in 25 suites
├── Resources/                            # Repo-level resources (served via GitHub raw URL)
│   └── catalogue.json                    # Production catalogue: London + York, 3 tours, 10 waypoints
├── Wanderpast/                           # Main iOS app
│   ├── Audio/AudioEngine.swift           # AVFoundation wrapper
│   ├── Location/
│   │   ├── LiveGeofenceManager.swift     # CoreLocation wrapper — in-tour waypoint triggering
│   │   └── LiveLocationProvider.swift    # CoreLocation wrapper — discovery (coarse, low-power)
│   ├── Tour/
│   │   ├── TourCoordinator.swift         # ObservableObject bridge to SwiftUI
│   │   ├── InTourView.swift              # In-tour UI (controls, Help I'm lost, completion overlay)
│   │   ├── CompletedToursStore.swift     # UserDefaults-backed wrapper around CompletedTours
│   │   ├── CompletionCardView.swift      # Post-tour keepsake with stylised cluster path
│   │   └── CompletedBadge.swift          # Reusable "COMPLETED" pill used on tour cards
│   ├── Account/
│   │   ├── AppleSignInController.swift   # async wrapper around ASAuthorizationAppleIDProvider
│   │   ├── AccountStore.swift            # ObservableObject — sign in/out, identity persistence, sync trigger
│   │   └── SettingsView.swift            # Sign in with Apple, account info, Sync now, Sign out
│   ├── Browse/
│   │   ├── CityBrowseViewModel.swift     # ObservableObject — wraps CatalogueRepository
│   │   ├── CityBrowseView.swift          # SwiftUI screen — list of city cards (NavigationLink → TourListView)
│   │   ├── TourListViewModel.swift       # ObservableObject — per-city tour list
│   │   ├── TourListView.swift            # SwiftUI screen — featured hero + more tours
│   │   ├── ThemeBrowseViewModel.swift    # ObservableObject — era-grouped browse
│   │   ├── ThemeBrowseView.swift         # SwiftUI screen — era sections (sibling entry, not wired yet)
│   │   ├── TourDetailViewModel.swift     # ObservableObject — single-tour detail
│   │   ├── PreviewClipButton.swift       # SwiftUI pill that streams a 60-sec preview via AudioEngine
│   │   └── NearbyToursViewModel.swift    # ObservableObject — combines repo + LiveLocationProvider into NearbyToursState
│   ├── DesignSystem/                     # Color, Typography, Spacing tokens
│   ├── Resources/
│   │   ├── Audio/                        # Bundled .m4a audio files
│   │   ├── Fonts/                        # Fraunces, Inter, JetBrains Mono
│   │   ├── sample_tour.json              # Hardcoded Tower of London tour (legacy; SampleData still uses it)
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
