# Deferred Decisions — Revisit if Greenlit for Production

These decisions were made to keep MVP scope tight and focused on validating the core experience. Each should be revisited if the product proves out and Immediate wants to invest seriously.

---

## Platform

| Decision | MVP | Revisit for production |
|----------|-----|----------------------|
| iOS only | Native Swift, no Android | Android (native Kotlin) build using same backend/content APIs |

## Commerce & monetisation

| Decision | MVP | Revisit for production |
|----------|-----|----------------------|
| No gift flow | Cut entirely | Gift purchases + redemption codes — natural fit for Father's Day, Christmas, birthdays. Significant revenue potential. |
| No subscription tier | City bundles + individual + annual pass only | Consider monthly subscription if usage patterns show regular repeat engagement across cities |
| Apple IAP only | 30% Apple cut accepted | Evaluate web-based purchase flow to reduce commission (permitted under EU DMA / recent Apple policy changes) |

## Features

| Decision | MVP | Revisit for production |
|----------|-----|----------------------|
| No journaling/badges | Simple completion card + editorial summary only | Photo attachments, collection badges, social sharing, progression systems |
| No offline download | Stream + pre-buffer only | Explicit "download for offline" option — becomes important if scope expands to rural/heritage sites with poor signal |
| Minimal map | Static overview + "help I'm lost" fallback to Apple Maps | Full interactive map with live position if user research shows navigation is a pain point |

## Identity & data

| Decision | MVP | Revisit for production |
|----------|-----|----------------------|
| Sign in with Apple only | Zero-friction auth, no Immediate ecosystem link | Immediate ID integration for cross-brand analytics, cross-sell (HE subscribers, RT readers), and unified user graph |
| Basic analytics | Firebase Analytics — 7 core events, real-time dashboard, free | Full Segment integration → Immediate data warehouse with cross-brand schema |
| No custom analytics tooling | Firebase dashboard for TestFlight, no custom builds | PostHog or Mixpanel for deeper product analytics; custom dashboards if needed |

## Content & coverage

| Decision | MVP | Revisit for production |
|----------|-----|----------------------|
| UK towns/cities only | London (hero) + 4-5 other cities | Battlefields, stately homes, rural heritage sites, international expansion |
| No user-generated content | Editorially produced tours only | UGC with moderation — community-contributed walks |
| English only | Single language | Multi-language narration for international tourists |
| Basic accessibility info | General note that tours are in pedestrianised urban areas | Per-tour accessibility notes (surface type, steps, gradients per waypoint), seated alternatives for less accessible sites |
