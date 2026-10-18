# NexusProbe - AI Coding Rules & Guidelines

**Version:** 1.1  
**Purpose:** Strict instructions for any AI (Grok, Claude, Antigravity, Cursor, etc.) working on this codebase.

---

## 1. Core Principles
- **Public data only** — Never attempt to access private data, authenticated sessions beyond user-provided cookies, or paid data brokers.
- **Ethical first** — Always include clear legal/ethical disclaimers. Never encourage stalking, harassment, or illegal surveillance.
- **Free by default** — Prefer free/open tools and public endpoints. Paid APIs only as optional upgrades.
- **Modular & clean** — One responsibility per service file. Keep `osint_runner.py` as thin orchestrator.
- **Async everywhere** — Use `async/await` + `httpx` or equivalent. No blocking calls in the request path.

---

## 2. Allowed Libraries & Tools
### Preferred / Approved
- FastAPI, Pydantic, httpx, asyncio
- Holehe, XposedOrNot, Maigret, Sherlock, GHunt
- Supabase Python client
- Next.js, Tailwind, shadcn/ui, Recharts
- Flutter (mobile)

### Avoid / Do Not Introduce Without Explicit Approval
- Selenium / Playwright for production (headless browser is heavy)
- Paid commercial APIs (Clearbit, FullContact, etc.) as required dependency
- Scraping of authenticated-only content
- Any library that stores or transmits user cookies outside the controlled environment

---

## 3. Coding Standards
- Type hints on all functions
- Pydantic models for every service response
- Consistent error handling: catch exceptions, log, return graceful fallback (never crash the whole search)
- Timeouts on every external request (default 8–15s)
- Rate limiting awareness (sleep / backoff when needed)
- No hardcoded secrets — everything via `config.py` / `.env`
- Comments only where logic is non-obvious

---

## 4. What the AI Should Do
- Always read existing service files before modifying
- Prefer enhancing existing modules over creating duplicates
- When adding a new data source → create a new `*_service.py` + update runner + models
- Update `profiles` list and frontend cards when new avatar/status data becomes available
- Keep Docker and requirements.txt in sync
- Write clear commit-ready code with meaningful variable names

---

## 5. What the AI Must NOT Do
- Never remove ethical disclaimers
- Never add features that require non-public data
- Never hardcode API keys or cookies
- Never break the in-memory fallback mode
- Never introduce breaking changes to the mobile API (`/api/v1/*`) without updating Flutter models
- Never assume paid services are available
- Do not rewrite the entire project in a different stack

---

## 6. Error Handling Rules
```python
try:
    # external call
except Exception as e:
    print(f"[ServiceName] Error: {e}")
    return FallbackResult(found=False)  # or empty list
```
Always return a valid object so the orchestrator can continue.

---

## 7. Frontend Rules
- Use existing shadcn/ui components
- Dark theme only (see Design.md)
- Every account card must support optional `avatar_url`
- Graceful fallback icons when no photo exists
- Keep loading skeletons and error states

---

## 8. Documentation Rules
- When adding a major feature → update PRD.md, Architecture.md, and Memory.md
- Keep Phases.md current with progress

---

**Next Document:** Phases.md
