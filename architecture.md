# Wanderpast — Architecture & Design

**Last updated:** 2026-04-25
**Status:** Pre-build, decisions finalised from discovery grilling

---

## 1. Product summary

**Wanderpast, by HistoryExtra** — GPS-triggered immersive audio history tours across UK towns and cities. Cluster-based mini-tours (30-45 minutes, 4-6 waypoints) deeply focused on a single theme, moment, or story. Present-tense narration layered over authentic period soundscapes to make history feel real at the location where it happened.

---

## 2. Experience model

### Cluster-based tours
Tours are concentrated in a tight geographic area (a cathedral close, a market square, a single street). Users move short distances between waypoints — this is not a cross-city walking route. The audio does the navigation via transitional narration cues.

### Tour structure
- **4-6 waypoints** per tour
- **4-6 minutes** of rich audio per waypoint
- **30-45 minutes** total duration
- Each tour focuses on **one core theme, moment in history, or story**

### Audio layers
Two audio channels running simultaneously:

1. **Pre-mixed waypoint audio** (triggered) — a single file per waypoint, produced in studio. Narration + timed sound effects baked together. Plays when user enters a waypoint's geofence. Stops when complete.
2. **Ambient soundscape loop** (continuous) — a separate looping track per tour/era that plays throughout. Medieval market sounds, Victorian street noise, etc. Dips during waypoint narration, comes back up during transitions. Keeps the user "in the world" at all times.

### Between waypoints
Soundscape bed continues. Short transitional narration cues guide the user to the next stop ("now look to your left and walk toward the stone archway..."). No silence, no dead air, no "press 4 now" feeling. The tour feels like one continuous piece of audio storytelling.

### Narration styles
Three modes, chosen per tour by editorial:

- **Present-tense omniscient** (default) — "It's 1349. The plague has reached this street..." Cinematic, atmospheric, consistent.
- **Character-led first person** (select tours) — a specific historical figure narrates as if there with you. Requires strong voice acting.
- **Expert-led** (select tours) — real HistoryExtra historians/editors narrate with their own authority and audience recognition.

These can blend within a single tour.

---

## 3. Technical architecture

### Platform
- **iOS only** (native Swift)
- No Android for MVP — revisit if product validates

### Native frameworks
- **AVFoundation** — audio playback, layering narration over soundscapes, background playback, lock screen controls, interruption handling
- **CoreLocation** — GPS positioning, geofence-based waypoint triggering
- **MapKit** — static overview map on tour detail screen (free, no API key)

### Backend
Deliberately minimal:

- **Tour content** — static JSON files deployed to a CDN. Tour metadata, waypoint coordinates, audio URLs, completion summaries. Version-controlled in the repo.
- **Audio files** — hosted on CDN (CloudFront or Cloudflare). Streamed with aggressive pre-buffering of next 2-3 waypoints. No offline download for MVP.
- **IAP verification** — single serverless function (AWS Lambda or similar) for Apple receipt validation + lightweight database for purchase state per user.
- **No traditional backend server** — this is a content delivery product with a thin purchase verification layer.

### Authentication
- **Sign in with Apple** only for MVP
- No Immediate ID integration until production

### Analytics
- **Firebase Analytics** — 7 core events:
  1. Tour started (which tour, timestamp, location confirmed)
  2. Waypoint triggered (which waypoint, time in geofence)
  3. Waypoint audio completed vs skipped
  4. Tour completed vs abandoned (and at which waypoint)
  5. Pause events (when and where)
  6. Preview clip played (which tour)
  7. "Help I'm lost" tapped (which waypoint)

### Content management
- **JSON files in the repo** for MVP (no CMS)
- Hand-edited, version-controlled, deployed to CDN on change
- CMS (likely Sanity) deferred to production

---

## 4. Commerce model

### Pricing tiers
- **£1.99** — single tour (impulse-buy conversion device)
- **£7.99** — city bundle (all tours in a city)
- **Annual all-cities pass** — price TBC (unlocks everything)

### Free tier
- **One free tour per city** — no account needed, no payment. Full experience. The tour itself is the marketing.

### Implementation
- Apple IAP for all purchases
- Serverless receipt validation
- No subscription tier for MVP
- No gift flow for MVP

---

## 5. Launch content

### Cities
- **London** (hero city) — 15-20 mini-tours
- **York** — 3-5 tours
- **Bath** — 3-5 tours
- **Edinburgh** — 3-5 tours
- **Oxford** — 3-5 tours
- **Canterbury** — 3-5 tours

### AI experiment
One fully AI-produced tour at the **Tower of London area**:
- Scripts: Claude/GPT-4 with editorial review for accuracy
- Voice: ElevenLabs TTS
- Soundscapes: stock sound libraries (Artlist, Epidemic Sound)
- Blind-tested against human-produced tours (testers not told which is AI)

### Content production (human tours)
- **Editorial** writes scripts and selects narrators (historians, in-house experts)
- **External sound designer** (freelance) handles soundscapes and final mix
- Hybrid model: editorial owns the creative, specialist owns the craft

---

## 6. App UX

### Discovery (at home / planning)
- Browse tours by city, theme/era
- Listen to 60-second preview clips
- Save tours to wishlist for future trips
- No full listening from home — the magic requires being there

### Discovery (on location)
- **Proximity-first** — shows tours nearest to current location ("there's a tour starting 200m from you")
- Theme/era browsing available
- Editorial "start here" pick per city (reduces choice paralysis)

### In-tour experience
- Audio triggers automatically on entering waypoint geofence
- Ambient soundscape plays continuously
- Manual skip/rewind available
- Pause/resume on headphone unplug, calls, other interruptions
- Lock screen media controls with tour + waypoint info
- "Help I'm lost" button opens Apple Maps to next waypoint
- No full interactive map during tour — audio guides navigation

### Tour completion
- **Completion card** with stylised visual of the cluster walked
- **Editorial summary** — written per tour, same for everyone. Recaps key moments and facts as a keepsake.
- Simple "completed" marker in the UI

### Post-tour survey (TestFlight only)
1. "How immersive did the experience feel?" — 1-5 stars
2. "How was the narration quality?" — 1-5 stars
3. "How were the background sounds and atmosphere?" — 1-5 stars
4. "Would you buy another tour like this?" — Yes / Maybe / No
5. One open text field

---

## 7. Brand & design

### Brand
- **Wanderpast, by HistoryExtra**
- "By HistoryExtra" appears on App Store listing and loading screen only
- App UI uses "Wanderpast" standalone

### Visual identity
- **Aesthetic**: premium editorial / museum exhibition
- **Palette**: warm paper (`#f4efe6`), deep ink (`#1a1713`), terracotta/ochre accent (`#a85a2a`)
- **Typography**: Fraunces (display/serif) + Inter (body/sans) + JetBrains Mono (overlines/metadata)
- **Feel**: dark, rich, minimal. Photography-led where available. Serif typography. Generous whitespace.

### Design reference
Mockup files in `/Users/matthewrance/Downloads/History Extra/`:
- `styles.css` — full design system (palette, type, components)
- `heroes.jsx` — hero section variants
- `shared.jsx` — tour cards, guide cards, navigation, footer components
- `Wanderpast Landing.html` — assembled landing page

Note: mockups show aspirational global scope (Rome, Kyoto, Berlin). MVP design should apply the same design language but reflect UK-only content and iOS app screens rather than web.

---

## 8. Launch strategy

### Phase 1: TestFlight beta
- 50-100 testers from HistoryExtra audience
- 3-5 London tours only (including 1 AI-produced)
- All tours free (testing experience quality, not pricing)
- Post-tour survey for blind AI vs human comparison
- Firebase analytics capturing 7 core events

### Phase 2: Soft launch
- App Store, no marketing push
- London tours + 1-2 additional cities
- Real IAP purchases enabled
- Validate pricing and conversion

### Phase 3: Full launch
- All 6 cities live
- HistoryExtra channel push (newsletter, podcast ads, website)
- QR codes / NFC at heritage sites and tourist info centres
- One free tour per city as primary conversion mechanism
