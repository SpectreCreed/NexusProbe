# Email OSINT Tool - Product Requirements Document (PRD)

**Date:** June 24, 2026  

## 1. Executive Summary

The **Email OSINT Tool** is a powerful, self-hosted investigative application that takes an email address as input and aggregates comprehensive public information about the associated individual. 

It delivers a rich, visual dashboard with profile photos, registered accounts, Google Maps reviews, active Google services, breaches, locations, usernames, and more — all from publicly available data sources.

**Key Goals**:
- Provide deep, actionable OSINT in a beautiful dark-themed UI
- Support both Web dashboard and Android (Flutter) app
- Fully free core (using open tools + XposedOrNot for breaches)
- Modular, expandable architecture with Supabase backend
- Ethical and responsible use focus

**Target Users**: Security researchers, journalists, investigators, and individuals performing legitimate OSINT.

## 2. Objectives & Success Metrics

- **MVP**: Functional email search returning profile summary, photos, accounts, breaches, and Google data within 30 seconds.
- **Adoption**: 100+ unique searches in first month post-launch.
- **Accuracy**: ≥80% of key data points sourced reliably with clear attribution.
- **Performance**: <5s response for cached searches, <45s for full scans.
- **User Satisfaction**: Clean, intuitive UI matching modern OSINT tools.

## 3. User Personas

- **Security Researcher** — Needs fast, comprehensive reports with export.
- **Journalist** — Values sources, timelines, and visual cards.
- **Individual User** — Wants simple mobile Android experience.

## 4. Core Features (Inspired by User Screenshots)

### 4.1 Profile Summary
- Names (variations from breaches, profiles)
- Usernames across platforms
- Profile photos grid (Gravatar + platform avatars)

### 4.2 Accounts & Platforms
- Registered Accounts (icons grid: Microsoft, Adobe, Etsy, Spotify, etc.)
- Detailed cards for major platforms (Adobe, Microsoft, GitHub, Chess.com, Duolingo, etc.)
- Status, joined dates, last seen, linked sign-ins

### 4.3 Google Ecosystem
- Active Google Apps (Maps, Meet, Drive icons, etc.)
- Google Maps Reviews (locations, ratings, dates, comments)
- Google User details (ID, type, last updated)

### 4.4 Experience & Professional
- LinkedIn-style employment history
- Company, role, dates

### 4.5 Locations
- Aggregated locations (country, city, SF, etc.) with source badges

### 4.6 Security & Breaches
- Breach exposure count and timeline (using XposedOrNot)
- Breach sources list
- Associated phone numbers from leaks

### 4.7 Media & Visuals
- Profile pictures gallery
- Platform-specific avatars

### 4.8 Dates & Links
- Comprehensive timeline (joined, last updated, breach first/last seen)
- Direct profile links with icons

### 4.9 Additional Features
- Bulk email upload (CSV)
- Report export (PDF, JSON, HTML)
- Search history (Supabase)
- Dark mode responsive UI
- Caching & rate limiting

## 5. Technical Architecture

### 5.1 Tech Stack
- **Backend**: FastAPI (Python)
- **Frontend**: 
  - Web: Tailwind CSS + HTMX
  - Android: Flutter
- **Database & Auth**: Supabase (PostgreSQL, Auth, Storage)
- **OSINT Core**:
  - Holehe (registered accounts)
  - Maigret / Sherlock (username hunting)
  - Gravatar (photos)
  - XposedOrNot (breaches)
  - httpx + BeautifulSoup (dorks & scraping)
  - Google dorks automation

### 5.2 Supabase Schema (Key Tables)
```sql
-- Users & Auth (Supabase built-in)
-- Searches
create table searches (
  id uuid primary key,
  user_id uuid references auth.users,
  email text,
  raw_results jsonb,
  created_at timestamp default now()
);

-- Cached Reports
create table reports (
  email text primary key,
  profile_data jsonb,
  last_updated timestamp
);
```

### 5.3 Data Flow
1. User inputs email (Web/Android)
2. Backend orchestrates modules (Holehe → Gravatar → XposedOrNot → Dorks)
3. Aggregate → Store in Supabase
4. Return rich JSON → Render beautiful cards

## 6. Non-Functional Requirements

- **Security**: API keys in environment, rate limiting, input sanitization
- **Privacy**: No storage of sensitive user data beyond searches; strong disclaimers
- **Performance**: Async processing, caching
- **Scalability**: Docker-ready, Supabase scaling
- **Legal**: Public data only, respect ToS, disclaimers everywhere

## 7. Roadmap & Versions

**Version 1.0 (MVP)**
- Core search with Holehe + Gravatar + XposedOrNot
- Basic dashboard cards
- Web + initial Flutter screens

**Version 1.1 (Current Plan)**
- Rich UI matching screenshots (photos grid, detailed cards, Google Maps)
- Supabase full integration
- Export features
- Android polish

**Version 2.0**
- Bulk search
- Advanced dorks & Maigret deep dive
- Timeline visualizations
- User accounts & history

## 8. Risks & Mitigations

- **Rate Limits**: Caching + backoff
- **Site Changes**: Modular design, easy updates
- **Legal**: Clear disclaimers, public data only
- **Data Accuracy**: Show sources and confidence

## 9. Appendix

- Responsible Use Policy
- Example JSON response structure
- Integration examples (XposedOrNot, Holehe)

---