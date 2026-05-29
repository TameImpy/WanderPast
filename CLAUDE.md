# Wanderpast — Project Instructions

## What this project is
Wanderpast is a GPS-triggered immersive audio history tour app for iOS, focused on UK towns and cities. Issues #2-#5 are partially or fully implemented. The app runs in the Xcode iOS Simulator with placeholder audio content.

## Current state
- **Pure logic layer** (`WanderpastCore` Swift Package): AudioEngineState, GeofenceState, TourService — 25 tests, all passing. Run with `cd Wanderpast/WanderpastCore && swift test`
- **Framework wrappers**: AudioEngine (AVFoundation), LiveGeofenceManager (CoreLocation), TourCoordinator (ObservableObject)
- **UI**: TourDetailView (tour info + "Start Tour"), InTourView (play/pause, skip, close)
- **Known issues**: geofence triggering unreliable in simulator (use skip buttons), checkpoint resume disabled, skip backward from idle doesn't work
- See `NEXT_STEPS.md` for full detail on what's done, what's broken, and what's next

## Key documents
Keep these documents accurate and up to date as the project evolves. When any decision, architecture choice, feature scope, or technical approach changes — whether through conversation with the user or as a consequence of implementation — update the relevant document(s) immediately:

- `architecture.md` — product design, technical architecture, experience model, commerce, launch strategy. This is the single source of truth for what we're building and how.
- `deferred_decisions.md` — decisions explicitly deferred from MVP. When something is cut or postponed, add it here with the MVP choice and what to revisit for production.
- `NEXT_STEPS.md` — current project status, known bugs, remaining work, and project structure. Update this at the end of every session.
- `brief_historyextra_walks.md` — the original product brief. Treat as historical context only — `architecture.md` supersedes it where they conflict.

## Working principles
- iOS only, native Swift. No React Native, no cross-platform.
- MVP scope is tight — do not add features, frameworks, or infrastructure beyond what `architecture.md` specifies without confirming with the user.
- The audio experience is the product. Technical decisions should serve immersion, not engineering elegance.
- When in doubt about scope, check `deferred_decisions.md` — if it's listed there, it's intentionally out of MVP.
- **Always use the TDD skill for implementation.** Tests first, then code. No exceptions. Pure logic goes in `WanderpastCore` Swift Package; framework wrappers go in the main Xcode project.
- Update `NEXT_STEPS.md` at the end of every session with current status.
