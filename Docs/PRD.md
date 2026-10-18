# NexusProbe - Product Requirements Document (PRD)

**Version:** 2.0  
**Last Updated:** July 19, 2026  
**Status:** Active Development  
**Owner:** SpectreCreed

---

## 1. Product Overview

**NexusProbe** is a self-hosted, privacy-respecting Open Source Intelligence (OSINT) platform that transforms limited public identifiers (email, username, full name, phone) into comprehensive public profiles.

It aggregates only publicly available data from sources such as social platforms, code repositories, breach databases, domain intelligence, and search engines. The tool is designed for legitimate investigative, educational, privacy-audit, and research purposes.

### Vision
Become the most usable, free/open, and feature-rich self-hosted email + person OSINT dashboard — inspired by tools like behindtheemail.com but fully controllable, extensible, and free of mandatory paid APIs.

### Target Users
- Security researchers and OSINT practitioners
- Privacy-conscious individuals performing self-audits
- Developers and bug bounty hunters
- Journalists and investigators (public data only)
- Students learning digital footprint analysis

---

## 2. Core Value Proposition
- Single input → rich multi-source public profile
- Fully self-hosted (Docker ready)
- Free by default (optional free APIs)
- Modern dark-themed dashboard with rich cards, charts, and photo grids
- Web + planned Android app
- Ethical by design: public data only, strong disclaimers, rate limiting

---

## 3. Functional Requirements

### 3.1 Input Types (Multi-Seed Support)
1. **Email Address** (Primary / Current)
2. **Username** (High priority)
3. **Full Name** (+ optional city/country)
4. **Phone Number** (with strong privacy warning)
5. **Existing Profile URL** (LinkedIn, GitHub, etc.)

### 3.2 Data Collection Modules
| Module | Source / Tool | Priority | Status |
|--------|---------------|----------|--------|
| Account Registration Check | Holehe | High | Implemented |
| Breach Detection | XposedOrNot | High | Implemented |
| Profile Photos | Gravatar + platform avatars | High | Partial |
| GitHub Profile | GitHub API / public | High | Implemented |
| Domain Intelligence | WHOIS + DNS | Medium | Implemented |
| Google Ecosystem | GHunt (cookies via .env) | High | Planned |
| Username Correlation | Maigret / Sherlock | High | Planned |
| Name-based Search | Google Dorks + people search | Medium | Planned |
| LinkedIn Public Profile | Public scraping / API | Medium | Planned |
| Google Maps / Local Guide | GHunt + dorks | Medium | Planned |
| Risk Scoring | Custom algorithm | High | Implemented |
| Connection Graph | Cytoscape.js / similar | Medium | Planned |

### 3.3 Dashboard Features
- Risk Score (0–100) with visual gauge
- Exposure Overview (charts)
- Registered Accounts (rich cards with icons, status, category)
- Profile Photos Grid
- Google Account + Active Google Apps
- Domain Intelligence
- Breaches list
- Experience / Career inferences
- Search History
- Export (JSON + PDF)
- Bulk search (CSV)

### 3.4 Non-Functional Requirements
- Fully free core (no paid APIs required)
- Docker + docker-compose support
- Supabase for auth, storage, history (optional – works in-memory)
- Rate limiting & caching
- Ethical disclaimers on every report
- Responsive dark UI
- Extensible plugin-style services

---

## 4. Success Metrics
- Successful extraction of Gravatar + at least 5 platform accounts for common emails
- Profile photos visible in dashboard
- Google Gaia ID / avatar / apps when cookies provided
- Username search returns results from ≥ 50 sites via Maigret
- Clean, modern UI matching reference screenshots

---

## 5. Out of Scope (for now)
- Paid data brokers
- Non-public / private data access
- Real-time surveillance
- Automated doxxing features
- Commercial SaaS multi-tenant features (self-hosted focus)

---

## 6. Legal & Ethical Guidelines
- Only public data
- Clear user disclaimers
- No stalking / harassment use cases supported
- Users responsible for compliance with local laws
- Strong rate limiting and respectful scraping practices

---

**Next Document:** Architecture.md
