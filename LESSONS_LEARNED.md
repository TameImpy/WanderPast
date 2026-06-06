# Wanderpast — Lessons Learned

A running log of non-obvious gotchas, tricky bugs, and architectural decisions whose rationale isn't visible in the code. Each entry should let a future contributor benefit without re-running the conversation that produced it.

Format per entry:
- **Date** — short title
- **What went wrong / what wasn't obvious**
- **Why**
- **Fix / decision**

---

## 2026-06-05 — Hero images can overflow the viewport horizontally

`.frame(maxWidth: .infinity)` on an `AsyncImage` is a *request*, not a *cap* — when the loaded asset's intrinsic aspect ratio is wide enough, SwiftUI lets the image expand past the parent. Fix: wrap in `GeometryReader` to derive a hard pixel width from the parent and pass it to `.frame(width:)`. See commit `67b7950`.

## 2026-06-05 — CoreLocation lives outside WanderpastCore; mirror it with a pure enum

Pure logic in `WanderpastCore` can't import CoreLocation (it's an iOS-only framework, and the package is meant to be testable on macOS). For Issue #7 the fix was to define `LocationAuthorization` and `Coordinate` as pure Sendable types in the package, then translate `CLAuthorizationStatus → LocationAuthorization` and `CLLocation → Coordinate` once at the framework wrapper boundary (`LiveLocationProvider`). The state mapper (`NearbyToursState.from(...)`) then takes only pure inputs and is fully unit-testable without iOS. Pattern: any time the pure layer needs a concept that CoreLocation/CoreData/MapKit exposes, define a mirror type in `WanderpastCore` and translate at the wrapper. Same approach as `WaypointRegion` in the geofence layer.

## 2026-06-06 — `@MainActor` initializer can't be called from a synchronous default-argument expression

In `AccountStore.init`, defaulting the `signInController:` parameter to `AppleSignInController()` failed to compile: `call to main actor-isolated initializer 'init()' in a synchronous nonisolated context`. Default-argument expressions are evaluated at the caller's actor context, which isn't guaranteed to be the main actor — even though `AccountStore` itself is `@MainActor`. Fix: take an optional parameter and resolve it inside the (main-actor) initializer body (`let resolved = passedIn ?? AppleSignInController()`). Same pattern would apply for any main-actor type used as a default in another main-actor type's init signature.

## 2026-06-06 — `Group { switch }` with `Label` arms can confuse the SwiftUI type checker

A `Group { switch state { case ... Label(...) case ... } }` in `SettingsView` failed with cryptic errors about `TableColumn` generic parameters — SwiftUI's builder tried to infer the wrong container type when the switch arms were heterogeneous (`EmptyView` vs `Label`). Fix: extract the switch into a `@ViewBuilder` private var or function; that bypasses the outer container inference path and resolves the arms independently. Pattern: prefer `@ViewBuilder` for any non-trivial switched UI rather than wrapping in `Group`.

## 2026-06-05 — `simctl privacy grant location` does not pre-authorize CoreLocation prompts

When verifying location-gated UI in the simulator, `xcrun simctl privacy <udid> grant location <bundle-id>` doesn't suppress the iOS authorization dialog the way it does for some other TCC services. The dialog still appears the first time `requestWhenInUseAuthorization()` is called, and the only way to advance the app past `.locating` to `.loaded` from CLI is to tap "Allow" in the simulator UI. `simctl` has no `tap` subcommand, and `osascript` keystroke control requires Accessibility permission for the host terminal — likely to fail in a headless context. For now, the `.loaded` state on the "Near you" section is verified manually; future automation will need `idb` or a similar UI driver.
