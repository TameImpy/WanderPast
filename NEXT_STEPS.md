# Wanderpast — Next Steps

**Delete this file once the steps below are complete.**

---

## Prerequisites (do these before resuming with Claude)

1. **macOS Tahoe upgrade** — should already be done (26.4.1)
2. **Install Xcode** from the Mac App Store
3. **Open Xcode once** — accept the license, let it install additional components
4. **Run this command in terminal:**
   ```
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```
5. **Verify it works:**
   ```
   swift --version
   xcodebuild -version
   ```

---

## Where we left off

### Completed
- Product discovery: 31-question grilling, all major decisions finalised
- `architecture.md` — single source of truth for what we're building
- `deferred_decisions.md` — what's explicitly out of MVP scope
- `CLAUDE.md` — project instructions for future sessions
- PRD submitted as GitHub issue #1 (https://github.com/TameImpy/WanderPast/issues/1)
- 15 implementation issues created (#2-#16) as vertical slices
- Issue #2 (Xcode project skeleton) — implemented, committed, pushed to main
- TDD plan approved for AudioEngine (#3) and GeofenceManager (#4)

### Next: TDD implementation of issues #3 and #4 (in parallel if possible)

**Issue #3: AudioEngine** (Wanderpast/Wanderpast/Audio/)
- Wraps AVFoundation for dual-channel audio (ambient loop + waypoint narration)
- Crossfade, background playback, lock screen controls, interruption handling
- Extract pure logic into `AudioEngineState` for testability
- TDD plan approved: 9 behaviours to test (see architecture.md section 2)

**Issue #4: GeofenceManager** (Wanderpast/Wanderpast/Location/)
- Wraps CoreLocation for GPS waypoint triggering
- Jitter suppression, manual advance, accuracy management
- Extract pure logic into `GeofenceState` for testability

**Approach:** Use the TDD skill (`/tdd`). Strict red-green-refactor — write failing test first, then implement. Create a Swift Package at `Wanderpast/WanderpastCore/` for the pure logic layers so `swift test` works from command line.

### After #3 and #4: Issue #5 (Tracer Bullet)
Wire AudioEngine + GeofenceManager + TourService together so a user can walk a tour end-to-end with audio triggering automatically. This is the first "magic moment."

---

## Key files to read for context
- `/Users/matthewrance/Documents/hiswalks/architecture.md` — product + technical architecture
- `/Users/matthewrance/Documents/hiswalks/deferred_decisions.md` — what's out of scope
- `/Users/matthewrance/Documents/hiswalks/CLAUDE.md` — project instructions
- `/Users/matthewrance/Documents/hiswalks/Wanderpast/` — Xcode project

## GitHub
- Repo: https://github.com/TameImpy/WanderPast
- PRD: Issue #1
- Implementation issues: #2 (done) through #16

## Critical rule
**Always use the TDD skill for implementation.** Tests first, then code. No exceptions.
