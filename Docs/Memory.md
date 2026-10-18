# NexusProbe - Project Memory / Progress Log

**Purpose:** Keep AI context updated across sessions. Update this file after every significant coding session.

**Last Updated:** July 20, 2026

---

## Current Status Summary
- Phase 1 complete: Profile photos, rich cards, and full Next.js dashboard are implemented.
- Gravatar `has_custom_avatar` detection working via `d=404` trick.
- Backend separates `real_photos` (genuine person photos) from `photos` (all platform images/favicons).
- `DashboardClient.tsx` fully rebuilt with polling, risk gauge, GitHub card, breach section, domain section.
- Jinja2 `dashboard.html` updated to use `real_photos` from backend.
- Next focus: Phase 2 — GHunt integration for Google ecosystem data.

---

## Key Decisions Made
- Preferred GHunt integration method: **Option 2** — base64-encoded cookies via `.env` (no interactive login).
- Stack remains FastAPI + Next.js + Supabase + Flutter.
- Focus on free/public tools only.
- Dark theme is permanent.

---

## Completed Work
- [x] Project structure and Docker
- [x] Basic search + polling API
- [x] Holehe account enumeration
- [x] XposedOrNot breach checks
- [x] Gravatar service (improved fallback + `has_custom_avatar` detection)
- [x] Risk scoring
- [x] Dashboard UI with cards and charts
- [x] Supabase + in-memory fallback
- [x] Documentation suite (PRD, Architecture, Rules, Phases, Design)
- [x] **Phase 1:** `real_photos` separation in `osint_runner.py` + `models.py`
- [x] **Phase 1:** Full `DashboardClient.tsx` rewrite (polling, risk gauge, GitHub card, breaches, domain)
- [x] **Phase 1:** Jinja2 `dashboard.html` aligned to use backend `real_photos`
- [x] **Phase 1:** GitHub profile details enriched (bio, blog, repos, created_at in profiles)

---

## In Progress / Known Issues
- Google service needs full GHunt integration (Phase 2)
- Maigret / username search not yet implemented (Phase 3)
- Jinja2 `dashboard.html` photo dict keys use `photo.url`/`photo.platform` — verify Jinja2 attr access vs dict access at runtime

---

## Immediate Next Tasks (Phase 2)
1. Integrate GHunt via base64 cookies in `.env` (`GHUNT_COOKIES_BASE64`)
2. Extract: Gaia ID, avatar, active Google Apps, Maps reviews
3. Add new rich `GoogleEcosystem` card with app badges
4. Update `config.py` with `ghunt_cookies_base64` setting

---

## Important File Locations
- Orchestrator: `app/services/osint_runner.py`
- Gravatar: `app/services/gravatar_service.py`
- Frontend dashboard: `frontend/src/components/DashboardClient.tsx`
- Models: `app/models.py`
- Config: `app/config.py`

---

## Notes for Future AI Sessions
- Always check this Memory.md first.
- Prefer small, focused changes over large rewrites.
- After coding, update the checkboxes and “Last Updated” date in this file.
- Keep ethical disclaimers intact.

---

**End of Memory Log**
