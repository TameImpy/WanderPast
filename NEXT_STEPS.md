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
- **Issue #3** (AudioEngine) — done. AudioEngineState pure state machine with 10 tests
- **Issue #4** (GeofenceManager) — done. GeofenceState pure state machine with 8 tests
- **Issue #5** (Tracer Bullet) — partially done. TourService state machine with 7 tests. Framework wrappers built. End-to-end audio playback working in simulator with skip forward/backward
- Design system fonts installed (Fraunces, Inter, JetBrains Mono)
- Placeholder audio: medieval ambient soundscape (Freesound), TTS narration for 3 waypoints

## Known issues to fix

### Checkpoint resume (temporarily disabled)
- `TourCoordinator.saveCheckpoint()` and `loadCheckpoint()` are commented out
- Problem: after completing a tour, restarting the app skips all waypoints (shows "3 of 3")
- **Fix needed:** add a "restart tour" button, or only resume if tour was abandoned mid-way (not completed)
- Files: `Wanderpast/Wanderpast/Tour/TourCoordinator.swift` lines 170-177

### Geofence triggering not working in simulator
- Setting custom location via Features → Location → Custom Location doesn't trigger `didEnterRegion`
- CoreLocation geofence monitoring is unreliable in the iOS Simulator
- Skip forward button works as a workaround
- **Fix options:** test on a real device, or add a development-mode "simulate geofence entry" button
- The GPX file (`Resources/TowerOfLondonWalk.gpx`) also didn't work — Xcode's Debug → Simulate Location menu was greyed out

### Skip backward doesn't work
- Tapping skip backward has no visible effect
- Likely the same issue as skip forward was — needs to handle the case where no waypoint is currently playing

### Ambient audio sourcing
- Current ambient is a Freesound placeholder — good enough for development
- Production needs: properly mixed ambient per tour/era from Artlist or Epidemic Sound
- Architecture.md specifies external sound designer (freelance) for final mix

### Narration is TTS placeholder
- All 3 waypoint narrations are macOS `say` command output
- Production needs: real voice actors or ElevenLabs (for the AI experiment tour)

## Next issues to tackle

### Issue #5 remaining work
- [ ] Get geofence triggering working (real device test or dev-mode simulate button)
- [ ] Fix skip backward from idle state
- [ ] Add "restart tour" flow
- [ ] Test background audio (screen locked, app backgrounded)
- [ ] Test lock screen media controls

### Issue #6 onwards
See GitHub issues #6-#16: https://github.com/TameImpy/WanderPast/issues

---

## Key files

- `architecture.md` — product + technical architecture
- `deferred_decisions.md` — what's out of scope
- `CLAUDE.md` — project instructions
- `Wanderpast/WanderpastCore/` — Swift Package with pure state machines (25 tests)
- `Wanderpast/Wanderpast/Audio/AudioEngine.swift` — AVFoundation wrapper
- `Wanderpast/Wanderpast/Location/LiveGeofenceManager.swift` — CoreLocation wrapper
- `Wanderpast/Wanderpast/Tour/TourCoordinator.swift` — orchestrator (ObservableObject)
- `Wanderpast/Wanderpast/Tour/InTourView.swift` — in-tour UI

## GitHub
- Repo: https://github.com/TameImpy/WanderPast
- PRD: Issue #1
- Implementation issues: #2 (done) through #16

## Critical rule
**Always use the TDD skill for implementation.** Tests first, then code. No exceptions.
