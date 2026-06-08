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

## 2026-06-08 — Apple Developer Program enrolment shows misleading "complete your purchase" UI while payment is processing

After paying £79 for the Apple Developer Program, the account page at developer.apple.com/account showed a "Matthew Rance (Pending)" badge plus a notice headed "Purchase your membership / To continue your enrollment, complete your purchase now." This looked like a prompt to pay again. It isn't. The "complete your purchase now" link is stale UI that doesn't refresh while Apple's payment processor settles the charge — it's there for users who quit the flow before paying. The signals that actually mean "we have your money, just wait" are: (a) the `(Pending)` badge, (b) the order confirmation email (e.g. "Your order is being processed W1884790031"), and (c) the line "Your purchase may take up to 48 hours to process." **Do not click "complete your purchase now"** while in pending state — it risks a duplicate order. Wait for the activation email titled "Welcome to the Apple Developer Program." In our case approval was effectively instant (minutes, not 48 hours).

## 2026-06-07 — Apple's `developer.apple.com/maintenance/` redirect can fire even when nothing's actually down

After signing the free Apple Developer Agreement, the portal bounced us to `developer.apple.com/maintenance/` with a "We'll be back soon" page, even though the System Status page showed every service — including "Account" and "Program Enrollment and Renewals" — as green/available. The maintenance page is sometimes triggered by a session/cookie state mismatch after agreeing to terms rather than an actual outage. Fix: open the enrolment URL in a **private/incognito window** to bypass the stale session, or wait an hour and try again. Always cross-check the System Status page before assuming the portal is genuinely down.

## 2026-06-06 — `@MainActor` initializer can't be called from a synchronous default-argument expression

In `AccountStore.init`, defaulting the `signInController:` parameter to `AppleSignInController()` failed to compile: `call to main actor-isolated initializer 'init()' in a synchronous nonisolated context`. Default-argument expressions are evaluated at the caller's actor context, which isn't guaranteed to be the main actor — even though `AccountStore` itself is `@MainActor`. Fix: take an optional parameter and resolve it inside the (main-actor) initializer body (`let resolved = passedIn ?? AppleSignInController()`). Same pattern would apply for any main-actor type used as a default in another main-actor type's init signature.

## 2026-06-06 — `Group { switch }` with `Label` arms can confuse the SwiftUI type checker

A `Group { switch state { case ... Label(...) case ... } }` in `SettingsView` failed with cryptic errors about `TableColumn` generic parameters — SwiftUI's builder tried to infer the wrong container type when the switch arms were heterogeneous (`EmptyView` vs `Label`). Fix: extract the switch into a `@ViewBuilder` private var or function; that bypasses the outer container inference path and resolves the arms independently. Pattern: prefer `@ViewBuilder` for any non-trivial switched UI rather than wrapping in `Group`.

## 2026-06-05 — `simctl privacy grant location` does not pre-authorize CoreLocation prompts

When verifying location-gated UI in the simulator, `xcrun simctl privacy <udid> grant location <bundle-id>` doesn't suppress the iOS authorization dialog the way it does for some other TCC services. The dialog still appears the first time `requestWhenInUseAuthorization()` is called, and the only way to advance the app past `.locating` to `.loaded` from CLI is to tap "Allow" in the simulator UI. `simctl` has no `tap` subcommand, and `osascript` keystroke control requires Accessibility permission for the host terminal — likely to fail in a headless context. For now, the `.loaded` state on the "Near you" section is verified manually; future automation will need `idb` or a similar UI driver.
