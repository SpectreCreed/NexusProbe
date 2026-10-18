# NexusProbe - Architecture Document

**Version:** 2.0  
**Last Updated:** July 19, 2026

---

## 1. High-Level Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Next.js Web    │     │  Flutter Mobile  │     │  External Tools │
│  (Dashboard)    │     │  (Android App)   │     │  (Maigret,      │
└────────┬────────┘     └────────┬─────────┘     │   GHunt, Holehe)│
         │                       │               └────────┬────────┘
         │      REST / JSON      │                        │
         └───────────┬───────────┘                        │
                     ▼                                    │
            ┌────────────────────┐                        │
            │   FastAPI Backend  │◄───────────────────────┘
            │  (app/main.py)     │
            └────────┬───────────┘
                     │
         ┌───────────┼───────────┐
         ▼           ▼           ▼
   ┌──────────┐ ┌─────────┐ ┌──────────┐
   │ Supabase │ │ In-Mem  │ │ External │
   │ (Auth +  │ │ Fallback│ │ APIs     │
   │  DB)     │ │         │ │          │
   └──────────┘ └─────────┘ └──────────┘
```

### Data Flow
1. User submits Email / Username / Name via Web or Mobile
2. Backend creates search record → queues `osint_runner.py`
3. Concurrent services (asyncio.gather) collect public data
4. Results assembled into `OsintResults` model
5. Stored in Supabase (or memory) and returned to frontend
6. Frontend renders rich cards, photos, charts, risk score

---

## 2. Technical Stack

| Layer          | Technology                          | Notes |
|----------------|-------------------------------------|-------|
| Backend        | Python 3.11+, FastAPI, Uvicorn      | Async first |
| Frontend (Web) | Next.js 14+, TypeScript, Tailwind, shadcn/ui | App router |
| Mobile         | Flutter + Dart                      | Planned full feature parity |
| Database       | Supabase (Postgres) + in-memory fallback | Auth + history |
| OSINT Engines  | Holehe, XposedOrNot, Maigret, GHunt, httpx | Public only |
| Charts         | Recharts / ApexCharts               | Risk + exposure |
| Containers     | Docker + docker-compose             | One-command deploy |
| Auth           | Supabase Auth (JWT)                 | Optional in dev |

---

## 3. Folder Structure

```
NexusProbe/
├── app/                          # FastAPI backend
│   ├── main.py
│   ├── config.py
│   ├── database.py
│   ├── models.py                 # Pydantic models
│   ├── routes/
│   │   ├── search.py
│   │   ├── api.py                # Mobile API
│   │   ├── auth.py
│   │   ├── reports.py
│   │   └── bulk.py
│   ├── services/                 # Modular OSINT services
│   │   ├── osint_runner.py       # Orchestrator
│   │   ├── gravatar_service.py
│   │   ├── holehe_service.py
│   │   ├── xposedornot_service.py
│   │   ├── github_service.py
│   │   ├── google_service.py     # GHunt integration
│   │   ├── domain_service.py
│   │   ├── username_service.py   # Maigret (planned)
│   │   ├── name_service.py       # Planned
│   │   ├── risk_scoring.py
│   │   └── dork_service.py
│   └── templates/                # Jinja2 (legacy web)
├── frontend/                     # Next.js app
│   ├── src/
│   │   ├── app/
│   │   ├── components/
│   │   │   ├── DashboardClient.tsx
│   │   │   └── ui/
│   │   └── lib/
│   └── ...
├── mobile/                       # Flutter app
├── static/
├── supabase_migration.sql
├── docker-compose.yml
├── requirements.txt
├── .env.example
├── PRD.md
├── Architecture.md
├── Rules.md
├── Phases.md
├── Design.md
└── Memory.md
```

---

## 4. Key Components

### Backend Services Pattern
Every service follows:
```python
async def fetch_xxx(email_or_username: str) -> ResultModel:
    # Respectful requests, timeouts, error handling
    # Return structured Pydantic model
```

Orchestrator (`osint_runner.py`) runs them concurrently with `asyncio.gather`.

### Frontend State
- Polling via `/api/v1/search/{id}/status`
- Once completed → fetch full results
- Render cards from `profiles[]` array + dedicated sections

### Configuration
- `.env` for secrets (Supabase, GHUNT_COOKIES_BASE64, etc.)
- Feature flags for experimental modules

---

## 5. Scalability & Performance Notes
- Async I/O throughout
- Caching of frequent lookups (Redis optional later)
- Rate limiting per IP / user
- Background tasks for long-running searches
- Bulk limited to 25 emails

---

**Next Document:** Rules.md
