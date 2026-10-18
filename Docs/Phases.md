# NexusProbe - Development Phases

**Version:** 2.0  
**Last Updated:** July 20, 2026

---

## Phase 0 – Foundation (Completed)
- [x] Project scaffolding (FastAPI + Next.js + Docker)
- [x] Supabase integration + in-memory fallback
- [x] Basic search flow + polling
- [x] Holehe account checks
- [x] XposedOrNot breaches
- [x] Gravatar service
- [x] Domain intelligence
- [x] Risk scoring
- [x] Basic dashboard UI

---

## Phase 1 – Profile Photos & Rich Cards ✅ (Completed)
**Goal:** Make profile photos and detailed account cards reliable.

- [x] Fix Gravatar `has_custom_avatar` detection via `d=404` trick
- [x] Enrich `profiles` list in `osint_runner.py` with avatars from GitHub, Google, etc.
- [x] Separate `real_photos` (genuine person photos) from favicon icons in backend
- [x] Profile Photos Grid at top of dashboard (Next.js frontend)
- [x] Improve individual account cards — enriched details grid
- [x] Full `DashboardClient.tsx` rewrite: polling, risk gauge, GitHub card, breach section, domain section
- [x] Ensure frontend correctly renders `avatar_url` in account cards
- [x] Update Jinja2 `dashboard.html` to use backend `real_photos` list

**Result:** Searching a known email with a GitHub profile shows the real GitHub avatar photo + rich account cards.

---

## Phase 2 – Google Ecosystem (High Priority)
**Goal:** Extract real Google data using GHunt.

- [ ] Integrate GHunt with base64 cookies via `.env` (Option 2 preferred)
- [ ] Extract: Gaia ID, avatar, active Google Apps, Maps activity / Local Guide
- [ ] New rich cards: Google Account + Active Google Apps
- [ ] Google Maps reviews section (if available)
- [ ] Update models + frontend sections

---

## Phase 3 – Username & Full Person Search
**Goal:** Expand beyond email.

- [ ] Add `username_service.py` using Maigret
- [ ] Support username as primary input
- [ ] Name-based search service (Google dorks + public people search)
- [ ] Correlation engine (link email ↔ username ↔ name)
- [ ] Update API and UI to accept multiple input types

---

## Phase 4 – Mobile App Polish
- [ ] Full feature parity in Flutter app
- [ ] Offline history view
- [ ] Export from mobile
- [ ] Push notifications for completed bulk scans (optional)

---

## Phase 5 – Advanced Features
- [ ] Connection Graph visualization
- [ ] Bulk CSV upload + queue
- [ ] PDF report improvements
- [ ] Plugin system for custom modules
- [ ] Watchlist / monitoring (future)

---

## Phase 6 – Production Hardening
- [ ] Better rate limiting & caching
- [ ] Proxy support for aggressive checks
- [ ] Comprehensive logging
- [ ] Automated tests
- [ ] Documentation site / usage guide

---

### Current Priority Order
1. Phase 1 (Photos + Cards)
2. Phase 2 (Google / GHunt)
3. Phase 3 (Username + Name)

---

**Next Document:** Design.md
