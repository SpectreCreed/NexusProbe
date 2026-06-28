"""
OSINT Runner — orchestrates all OSINT modules concurrently and assembles the final result.
"""
from __future__ import annotations
import asyncio
import json
from typing import List, Dict, Any

from app import database
from app.models import OsintResults, Experience, ExperienceEntry
from app.services.gravatar_service import fetch_gravatar
from app.services.xposedornot_service import fetch_breaches
from app.services.domain_service import fetch_domain_intel
from app.services.holehe_service import check_accounts
from app.services.risk_scoring import calculate_risk
from app.services.dork_service import fetch_dork_results
from app.services.github_service import fetch_github_profile
from app.services.google_service import fetch_google_ecosystem


async def run_osint(search_id: str, email: str) -> None:
    """Main OSINT orchestrator."""
    database.update_search(search_id, status="processing")

    errors = {}

    try:
        # Run all modules concurrently
        tasks = [
            asyncio.create_task(fetch_gravatar(email)),
            asyncio.create_task(fetch_breaches(email)),
            asyncio.create_task(fetch_domain_intel(email)),
            asyncio.create_task(check_accounts(email)),
            asyncio.create_task(fetch_dork_results(email)),
            asyncio.create_task(fetch_github_profile(email)),
            asyncio.create_task(fetch_google_ecosystem(email)),
        ]

        (
            gravatar_result,
            (breaches, xon_error),
            domain_result,
            accounts,
            dork_results,
            github_result,
            (google_result, google_error),
        ) = await asyncio.gather(*tasks, return_exceptions=False)

        if xon_error:
            errors["xon"] = str(xon_error)

    except Exception as exc:
        print(f"[Runner] Fatal error for {email}: {exc}")
        database.update_search(search_id, status="failed", error_message=str(exc))
        return

    # Build rich profiles list for detailed UI cards
    profiles: List[Dict[str, Any]] = []
    photos: List[Dict[str, str]] = []

    # Gravatar
    if gravatar_result and gravatar_result.found:
        if gravatar_result.avatar_url:
            photos.append({"platform": "Gravatar", "url": gravatar_result.avatar_url})
        profiles.append({
            "platform": "Gravatar",
            "avatar_url": gravatar_result.avatar_url,
            "name": gravatar_result.display_name or email.split('@')[0],
            "username": gravatar_result.display_name or "",
            "url": gravatar_result.profile_url,
            "status": "Active",
            "details": {"type": "Profile"}
        })

    # GitHub
    if github_result:
        if github_result.avatar_url:
            photos.append({"platform": "GitHub", "url": github_result.avatar_url})
        profiles.append({
            "platform": "GitHub",
            "avatar_url": github_result.avatar_url or "",
            "name": github_result.name or github_result.username,
            "username": github_result.username,
            "url": github_result.html_url,
            "status": "Active",
            "details": {
                "followers": getattr(github_result, 'followers', None),
                "company": getattr(github_result, 'company', None),
                "location": getattr(github_result, 'location', None),
            }
        })

    # Google Ecosystem
    if google_result and google_result.found:
        if google_result.avatar_url:
            photos.append({"platform": "Google", "url": google_result.avatar_url})
        profiles.append({
            "platform": "Google",
            "avatar_url": google_result.avatar_url or "",
            "name": "Google Account",
            "username": email.split('@')[0],
            "url": "",
            "status": "Active",
            "details": {
                "type": "Registered",
                "local_guide": "Yes" if getattr(google_result, 'local_guide', False) else "No",
                "apps": str(len(google_result.active_apps)) + " Active Apps" if google_result.active_apps else "None"
            }
        })

    # Holehe Accounts → Rich Cards
    for acc in accounts:
        if acc.exists and acc.service:
            domain = f"{acc.service}.com" if not "." in acc.service else acc.service
            favicon_url = f"https://www.google.com/s2/favicons?domain={domain}&sz=128"
            photos.append({"platform": acc.service.title(), "url": favicon_url})
            profiles.append({
                "platform": acc.service.title(),
                "avatar_url": favicon_url,
                "name": f"{acc.service.title()} Account",
                "username": acc.username or "",
                "url": acc.url or "",
                "status": "Active",
                "details": {
                    "type": "Registered",
                    "category": getattr(acc, 'category', 'Other')
                }
            })

    # Calculate risk
    risk = calculate_risk(
        breaches=breaches,
        accounts=accounts,
        has_gravatar=bool(gravatar_result and gravatar_result.found),
        has_domain_intel=bool(domain_result),
    )

    # Experience (LinkedIn-style)
    experience = Experience(found=bool(github_result and getattr(github_result, 'company', None)), entries=[])
    if github_result and getattr(github_result, 'company', None):
        experience.entries.append(ExperienceEntry(
            company=github_result.company,
            role="Contributor / Developer",
            date_range="Present"
        ))

    # Full results
    results = OsintResults(
        email=email,
        gravatar=gravatar_result,
        github=github_result,
        google_data=google_result,
        experience=experience,
        breaches=breaches,
        breach_count=len(breaches),
        accounts=accounts,
        account_count=len([a for a in accounts if a.exists]),
        domain=domain_result,
        risk=risk,
        dorks=dork_results,
        errors=errors,
        photos=photos,
        profiles=profiles,   # Rich profiles for detailed cards
    )

    database.update_search(
        search_id,
        status="completed",
        results=json.loads(results.model_dump_json()),
    )