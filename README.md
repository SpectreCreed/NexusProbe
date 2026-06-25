# 🔍 NexusProbe

A powerful, self-hosted email intelligence platform. Transform any email address into a comprehensive public profile using Open Source Intelligence (OSINT).

![Stack](https://img.shields.io/badge/FastAPI-0.111-009688?style=flat-square&logo=fastapi)
![Stack](https://img.shields.io/badge/Python-3.11+-3776AB?style=flat-square&logo=python)
![Stack](https://img.shields.io/badge/Supabase-Optional-3ECF8E?style=flat-square&logo=supabase)
![Stack](https://img.shields.io/badge/Tailwind-CDN-06B6D4?style=flat-square&logo=tailwindcss)

---

## ✨ Features

| Feature | Status |
| :--- | :---: |
| 🔓 Data Breach Detection (XposedOrNot) | ✅ |
| 🌐 Account Registration Check (Holehe) | ✅ |
| 🔍 Domain WHOIS + DNS Intelligence | ✅ |
| 👤 Gravatar Profile Discovery | ✅ |
| ⚠️ Risk Score (0–100) | ✅ |
| 📊 Interactive Charts | ✅ |
| 📄 PDF & JSON Export | ✅ |
| 🕒 Search History | ✅ |
| 🔐 Supabase Auth | ✅ |
| 🐳 Docker Support | ✅ |

---

## 🚀 Quick Start

### 1. Clone / Navigate to project

```bash
cd "e:/NexusProbe"
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure environment

Copy `.env.example` to `.env` and fill in your values:

```bash
copy .env.example .env
```

Edit `.env`:
```env
# Required for DB persistence (optional for dev mode)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key

# Change this in production
APP_SECRET_KEY=your-random-secret-32chars
```

> **Dev Mode**: The app works fully **without Supabase** — it uses an in-memory store. Searches won't persist between restarts, but everything else works.

### 4. Run the app

```bash
uvicorn app.main:app --reload --port 8000
```

Open [http://localhost:8000](http://localhost:8000)

---

## 🐳 Docker

```bash
docker compose up --build
```

---

## 🗄️ Supabase Setup (Optional)

1. Create a free project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** and run `supabase_migration.sql`
3. Copy your **Project URL** and **anon key** into `.env`

---

## 📁 Project Structure

```
NexusProbe/
├── app/
│   ├── main.py              # FastAPI entry point
│   ├── config.py            # Settings from .env
│   ├── database.py          # Supabase client + in-memory fallback
│   ├── models.py            # Pydantic data models
│   ├── routes/              # HTTP route handlers
│   │   ├── search.py        # Search + polling
│   │   ├── auth.py          # Login/register/logout
│   │   └── reports.py       # History + exports
│   ├── services/            # OSINT modules
│   │   ├── osint_runner.py  # Orchestrator (asyncio.gather)
│   │   ├── holehe_service.py
│   │   ├── xposedornot_service.py
│   │   ├── domain_service.py
│   │   ├── gravatar_service.py
│   │   └── risk_scoring.py
│   └── templates/           # Jinja2 HTML templates
├── static/
│   ├── css/app.css          # Glassmorphism + animations
│   └── js/app.js            # Chart.js + ApexCharts init
├── .env                     # Your configuration
├── requirements.txt
├── supabase_migration.sql   # Run once in Supabase SQL Editor
└── docker-compose.yml
```

---

## 🔑 API Keys

| Service | Required | Free? | Link |
| :--- | :---: | :---: | :--- |
| Supabase | Optional | ✅ | [supabase.com](https://supabase.com) |

---

## ⚖️ Legal & Ethics

This tool is for **educational and legitimate investigative purposes only**.

- Only collects publicly available data
- Users must comply with applicable laws
- Respect individuals' privacy
- Do not use for stalking, harassment, or unauthorized surveillance

---

## 🛣️ Roadmap

- [ ] Phase 2: Bulk CSV upload + batch processing
- [ ] Phase 2: Connection graph visualization (Cytoscape.js)
- [ ] Phase 3: Watchlist + breach alert notifications
- [ ] Phase 3: RESTful API endpoints
- [ ] Phase 3: Plugin system for custom OSINT modules
