# Project Brief — HistoryExtra Walks

**Status:** Discovery → MVP build
**Owner:** Matt (Data Product & AI Innovation)
**Intended consumer:** Coding agent (Claude Code / equivalent) + human reviewer

---

## How to use this brief

This brief is written to be fed to a coding agent as the root context for implementation. It defines:

- What we are building and why (sections 1–3)
- What is and isn't in MVP (sections 4–5)
- Architectural direction where it matters, with explicit delegation where it doesn't (sections 6–9)
- Acceptance criteria the agent must hit (section 10)
- Open questions requiring human decision — **these must not be guessed** (section 12)

Unlike the other two briefs in this set, this product has non-trivial mobile engineering requirements around GPS, background audio, and geofencing. Pay attention to section 9.

---

## 1. Product overview

**One-liner:** GPS-triggered audio history walks across the UK, narrated by HistoryExtra's historian network — the authoritative British alternative to VoiceMap, Rick Steves, and the fragmented audio-tour market.

**Elevator pitch:** UK domestic tourism, heritage-site membership (NT ~5m, EH ~1.3m), and podcast-native adult audiences create overlapping demand pools of 6m+ UK adults alone, before factoring in 38m+ international visitors. Current audio-walk providers are either generic (SmartGuide) or not UK-authored (Rick Steves). HistoryExtra can own the category with editorial authority and its existing historian relationships.

**Year-one target:** 20,000 paying customers (blend of subscription and one-off purchases), at ~£5.99/month or ~£49/year subscription + £3–5 per one-off walk (pricing TBC — see section 12).

---

## 2. Problem

Engaged history-interested walkers and tourists in the UK currently have:

- Paper guidebooks — heavy, inflexible, quickly dated
- Generic audio-tour apps — SmartGuide, Rick Steves, VoiceMap — with uneven UK coverage and no editorial authority
- On-site paid tours — expensive, scheduled, variable quality
- Tourist information — free but shallow

Nothing combines authoritative British historical narration, proper GPS triggering, and a modern phone-first experience. It is genuinely an open category.

---

## 3. Target users

**Primary persona — "David & Sarah, 55 & 52":** UK domestic tourists on a weekend in Bath or York. National Trust members. Will pay for a richer experience than the tourist-info leaflet. Listen to podcasts on long drives.

**Secondary persona — "Amir, 42, solo traveller from abroad":** In London for three days. Wants serious historical context, not Buckingham Palace fluff. Will buy one-off walks rather than a subscription.

**Tertiary — gift buyer.** Father's Day, birthdays. Adult children buying experiences for history-loving parents. A meaningful seasonal conversion surface.

---

## 4. MVP scope (v1.0)

Ship in this order. GPS/audio engine is the critical path.

### 4.1 Walk library (core)
- 30–40 walks at launch, distributed across:
  - **London** (5–7): Roman, Medieval, Tudor, Blitz, Royal Westminster, East End, City of London
  - **Major historic cities** (12–15): Bath, York, Edinburgh, Oxford, Cambridge, Canterbury, Chester, Stratford, Winchester, Durham, Lincoln
  - **Battlefields** (3–4): Hastings, Bosworth, Culloden, Towton
  - **Stately homes / grounds** (5–8) pending partnership conversations — see section 12
- Each walk: 60–90 minutes audio, 2–5km route, 8–15 waypoints
- Each walk has: intro screen (difficulty, distance, time, accessibility notes), map preview, historian bio, sample audio clip

### 4.2 GPS audio engine (core)
- Background audio playback continues with phone locked and screen off
- GPS-triggered waypoints auto-play when user enters a radius
- "Continue from last position" after pause, interruption, or app relaunch
- Manual waypoint skip/rewind
- Offline mode: full audio + map cached on device post-purchase
- Clear progress indication throughout the walk

### 4.3 Commerce (core)
- Per-walk purchases (£3–5 range) via native IAP
- Subscription unlocks full library (monthly + annual) via native IAP
- Gift flow: purchase walk or subscription for another user, delivered as redemption code

### 4.4 Simple journaling (free, light)
- "Walks completed" log with date and photo attachment
- Badges for collections (e.g. "All London Medieval walks")
- Share completion to social (optional)

### 4.5 Account & identity
- Immediate ID integration
- Cross-device sync of purchases and progress

---

## 5. Out of scope (explicitly deferred)

- **User-generated walks.** Tempting but quality control and moderation cost is prohibitive. v2+.
- **AR / visual overlays.** Battery cost and engineering complexity wipes out MVP runway. Defer.
- **Multi-language.** English only. International visitors are a target audience but still comfortable in English.
- **Custom routing / navigation.** We provide a route; we don't offer turn-by-turn reroute if the user wanders. They can find the next waypoint themselves.
- **Apple Watch / CarPlay.** Nice-to-have, not MVP.
- **Live events / guided group walks.** Different business model; defer.
- **Web version.** Mobile-only makes sense for this product.

---

## 6. Core user journeys

**New user discovery + purchase:**
1. Install app — triggered by social ad, QR at heritage site, RT/HE magazine promo, or App Store search
2. Browse walks by city, theme, duration, or popularity
3. Tap walk → preview screen with sample audio (30 sec free) + full detail
4. Purchase: one-off (£3–5) or sub-trial (7 days free then £5.99/mo)
5. Download walk + map for offline use
6. Ready to walk

**In-walk experience:**
1. Tap "Start walk" — GPS permission requested with clear value prop
2. App guides to start point (simple map, no turn-by-turn)
3. On entering start waypoint radius → intro audio auto-plays
4. User walks; next waypoint audio triggers automatically on arrival
5. User can pause/skip/rewind manually
6. Completion: "walk completed" card with summary stats, prompt to journal or share

**Gift purchase:**
1. Tap "Gift" on walk or subscription
2. Enter recipient email + desired delivery date + personal note
3. Pay via IAP
4. Recipient receives code; redeems via app install or existing account

---

## 7. Data model (high-level)

Core entities:

- `Walk` — title, city, themes, duration_minutes, distance_km, difficulty, accessibility_notes, hero_media, historian_id, price_gbp, status
- `Waypoint` — walk, order, latitude, longitude, trigger_radius_m, audio_url, transcript, image_urls, notes
- `RouteSegment` — walk, from_waypoint, to_waypoint, polyline, walking_directions_text
- `User` — Immediate ID, subscription_status, owned_walks, progress_by_walk
- `WalkSession` — user, walk, started_at, completed_at, waypoints_triggered[], pause_points[]
- `Historian` — name, bio, photo, credentials
- `Purchase` — user, product_type (walk/sub/gift), amount, platform, timestamp
- `GiftCode` — purchaser, recipient_email, code, product, redeemed_by, redeemed_at

Note: waypoint audio should be versioned — if a factual correction is made post-launch, we can redeploy audio without breaking user-owned content.

---

## 8. Technical architecture (recommended direction)

**Client:** React Native **with native modules** for audio and geolocation, or full native (Swift + Kotlin) if the agent judges RN's background audio / GPS reliability insufficient. This is a genuine technical call — do not default to RN reflexively. The GPS + audio background-playback reliability is core to UX and the RN ecosystem here has known pitfalls. Benchmark early.

- If RN: use `react-native-track-player` for audio and `react-native-geolocation-service` or native foreground service for GPS
- If native: Swift AVFoundation + CoreLocation; Kotlin ExoPlayer + FusedLocationProvider

**Backend:** Node/TypeScript, lightweight. Most of this product is content delivery + purchase state.

**Maps:** Mapbox. Justification: offline tile support is mature, cheaper than Google at our expected volumes, and styling is superior for this use case. Apple Maps / Google Maps are fallback.

**Audio CDN:** Cloudflare or AWS CloudFront. Audio files are static, pre-encoded in multiple bitrates for adaptive delivery.

**Payments:** Native IAP only for MVP. Gift purchases through native IAP flows.

**CMS:** Reuse Immediate editorial CMS if it can model `Walk → Waypoint` with geographic data. Otherwise Sanity is strongly preferred here over Contentful (better handling of ordered rich-media content). Editorial must be able to:
- Upload audio files
- Set GPS coordinates via embedded map
- Preview the walk in a testing mode without leaving the building

**Analytics:** Segment → Immediate data warehouse. Instrument extensively — see section 11.

---

## 9. Mobile engineering — specific requirements

**This section is non-negotiable. The linear-tracker agent should treat these as tickets in their own right, not assumed consequences of other work.**

### Background audio
- Audio must continue when screen is locked or phone is in pocket
- iOS: configure audio session for `playback` category with `mixWithOthers: false`; declare `UIBackgroundModes` audio
- Android: use a foreground service with appropriate notification; handle audio focus changes (calls, other audio apps)
- Pause/resume on headphone unplug, call interruption, other audio taking focus
- Lock screen + control centre media controls with walk title, waypoint title, and artwork

### GPS and geofencing
- Use appropriate location accuracy mode — `kCLLocationAccuracyBest` during active walks only, reduced when backgrounded without active walk
- Geofence-based waypoint triggering: enter zone → waypoint audio auto-plays if not already heard
- Handle "jitter" — user standing near boundary shouldn't trigger audio repeatedly
- Battery realism: document expected battery drain per hour-of-walk (target: <15%)
- Graceful degradation when GPS signal is poor (dense urban, under trees) — allow manual advance

### Offline
- Pre-download all audio + map tiles for owned walks on Wi-Fi by default
- User-visible storage management: see what's downloaded, free up space
- Walk must be fully usable with zero signal — mission-critical for rural walks (Culloden, Bosworth etc.)

### Testing
- Location simulation in dev for CI and end-to-end testing
- Physical on-foot test for every walk before publication — not optional, part of the publishing workflow
- Battery instrumentation tests per release

---

## 10. Acceptance criteria for MVP

MVP is complete when:

- [ ] 30 walks are published, on-foot-verified, and available on iOS and Android
- [ ] A user can discover, preview, purchase, download, and complete a walk offline end-to-end
- [ ] Background audio + GPS triggering work reliably on a 60-minute walk with screen locked on both platforms
- [ ] Battery drain is <15% for a 60-minute walk with a typical charge level
- [ ] Gift flow works end-to-end (purchase + redemption) on iOS and Android
- [ ] Subscription and one-off purchases coexist in IAP without state corruption
- [ ] Full walk audio + maps cached for offline use before user leaves Wi-Fi
- [ ] Waypoint audio can be updated post-publication without breaking user ownership
- [ ] App Store / Play Store review passes on first submission (budget for rejection regardless)
- [ ] Editorial content pipeline is self-serve — new walks can be published without engineering involvement

---

## 11. First party data / analytics priorities

This is a uniquely data-rich product — location, duration, completion, waypoint-level engagement. The Data Product & AI Innovation angle is strong here.

MVP must capture:

- Walks purchased vs completed (strong engagement signal)
- Waypoint completion rates per walk (identifies editorial weak spots)
- Pause points (where users disengage — route issue? audio issue? physical tiredness?)
- Completion time vs expected (real walk durations vary wildly)
- Replay behaviour (strong content quality signal)
- Discovery → purchase funnel per source (organic / social / heritage partner / RT/HE channels)
- Seasonality patterns (essential input for content commissioning)

These events must flow into the central Immediate data warehouse with schema that allows cross-brand analysis (e.g. correlation with HE subscribers, Gardeners' World audience etc.).

---

## 12. Open questions — DO NOT GUESS

**These require human decision before implementation. The coding agent must pause and request clarification when it hits any of these.**

1. **Pricing** — £5.99/mo, £49/yr, £3–5 per walk are placeholders. A/B testing post-launch but initial anchors need commercial sign-off.
2. **Partnership strategy** — a co-brand with National Trust, English Heritage, or Historic Royal Palaces could front-load distribution significantly. This is a commercial conversation that should happen in parallel with build, and outcomes affect marketing + content priorities.
3. **Historian talent agreements** — contracts must cover long-term content reuse, cross-format use (walk audio → podcast episode), and revenue sharing. Block publication until resolved.
4. **Launch walks list** — 30–40 walks is the target, but specific cities/battlefields/houses should be sequenced by editorial + commercial together. Partnership deals may shift this.
5. **Accessibility content strategy** — some historic sites are not wheelchair-accessible. Do we publish the walk with a warning, or commission a seated alternative? Editorial + legal decision.
6. **Refund policy for GPS failure** — edge case but real. If a user bought a walk and GPS fails mid-walk, what's the policy? Commercial + support decision.
7. **RN vs native** — see section 8. Engineering call informed by an early spike.

---

## 13. Suggested ticket structure (epic → ticket)

**Epic 1: Platform foundation**
- Client app skeleton (RN or native per section 8 spike)
- Immediate ID integration
- CI/CD + crash reporting
- Analytics wiring

**Epic 2: Content platform**
- CMS schema for Walk / Waypoint / RouteSegment / Historian
- Audio upload + versioning
- Map-based waypoint editor
- Editorial preview mode (simulate walk from desk)
- Content API

**Epic 3: Mobile audio + GPS engine** *(critical path — start spike immediately)*
- Background audio playback (iOS + Android)
- Geofence-based waypoint triggering
- Offline caching (audio + map tiles)
- Session state persistence
- Battery / reliability instrumentation

**Epic 4: Discovery + walk experience UX**
- Walk browse (by city, theme, duration)
- Walk detail + preview
- In-walk UI (map, waypoint indicator, player controls)
- Completion flow + journaling

**Epic 5: Commerce**
- Native IAP integration for one-off purchases
- Native IAP integration for subscriptions
- Purchase state reconciliation
- Gift flow (purchase + redemption)

**Epic 6: Pre-launch hardening**
- On-foot testing protocol for every walk
- Battery drain benchmarking
- App store submission prep (iOS + Android separately)
- Beta cohort via existing HE/RT audiences

---

## 14. Risks

- **Background audio reliability.** This is the single highest-risk technical area. Both iOS and Android have changed background execution policies over the years, and RN wrappers are known to lag. Spike and benchmark early.
- **Battery drain.** Users who see >25% drain on a 60-minute walk will uninstall. Real-device testing, not simulator, is required.
- **Content production cost per walk.** A decent walk involves historian time, scriptwriting, studio recording, editing, fact-checking, GPS waypoint surveying, and on-foot verification. Budget realistically — this is probably £3–5k per walk fully loaded. Content pipeline economics need sign-off before scale commitments.
- **Seasonality.** Audio walking is a spring/summer product. CAC / retention modelling needs to assume a winter trough.
- **Partnership dependencies.** If NT/EH conversations land, they're a major growth lever. If they don't, we're acquiring customers the hard way. Commercial should brief build team as soon as direction is clear.
- **App store review.** Both stores have specific policies around location use and IAP. Reviews from scratch can take 7+ days; budget for two rejections minimum.
