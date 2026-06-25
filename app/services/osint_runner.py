"""
OSINT Runner — orchestrates all OSINT modules concurrently and assembles the final result.
Updates the search record in the database as it progresses.
"""
from __future__ import annotations
import asyncio
import json
from typing import Optional

from app import database
from app.models import OsintResults
from app.services.gravatar_service import fetch_gravatar
from app.services.xposedornot_service import fetch_breaches
from app.services.domain_service import fetch_domain_intel
from app.services.holehe_service import check_accounts
from app.services.risk_scoring import calculate_risk
from app.services.dork_service import fetch_dork_results
from app.services.github_service import fetch_github_profile
from app.services.google_service import fetch_google_ecosystem
from app.models import Experience, ExperienceEntry


async def run_osint(search_id: str, email: str) -> None:
    """
    Main OSINT orchestrator. Called as a FastAPI BackgroundTask.
    Runs all modules concurrently, saves results, and marks the search complete.
    """
    # Mark as processing
    database.update_search(search_id, status="processing")

    errors = {}

    try:
        # Run all modules concurrently
        gravatar_task  = asyncio.create_task(fetch_gravatar(email))
        xon_task       = asyncio.create_task(fetch_breaches(email))
        domain_task    = asyncio.create_task(fetch_domain_intel(email))
        accounts_task  = asyncio.create_task(check_accounts(email))
        dork_task      = asyncio.create_task(fetch_dork_results(email))
        github_task    = asyncio.create_task(fetch_github_profile(email))
        google_task    = asyncio.create_task(fetch_google_ecosystem(email))

        (
            gravatar_result,
            (breaches, xon_error),
            domain_result,
            accounts,
            dork_results,
            github_result,
            (google_result, google_error),
        ) = await asyncio.gather(
            gravatar_task,
            xon_task,
            domain_task,
            accounts_task,
            dork_task,
            github_task,
            google_task,
            return_exceptions=False,
        )

        if xon_error:
            errors["xon"] = xon_error

    except Exception as exc:
        print(f"[Runner] Fatal error for {email}: {exc}")
        import traceback; traceback.print_exc()
        database.update_search(
            search_id,
            status="failed",
            error_message=str(exc),
        )
        return

    # Calculate risk score
    risk = calculate_risk(
        breaches=breaches,
        accounts=accounts,
        has_gravatar=gravatar_result.found if gravatar_result else False,
        has_domain_intel=True,
    )

    # Assemble Experience from github
    experience = Experience(found=False, entries=[])
    if github_result and github_result.company:
        experience.found = True
        experience.entries.append(
            ExperienceEntry(
                company=github_result.company,
                role="Unknown",
                date_range="Present"
            )
        )

    # Assemble full results
    results = OsintResults(
        email=email,
        gravatar=gravatar_result,
        github=github_result,
        google_data=google_result,
        experience=experience,
        breaches=breaches,
        breach_count=len(breaches),
        accounts=accounts,
        account_count=sum(1 for a in accounts if a.exists),
        domain=domain_result,
        risk=risk,
        dorks=dork_results,
        errors=errors,
    )

    # Persist results
    database.update_search(
        search_id,
        status="completed",
        results=json.loads(results.model_dump_json()),
    )
