"""
GitHub Service — Phase 2+ enrichment.
Searches GitHub for a user by email address, then fetches their full profile.

GitHub Search API: https://api.github.com/search/users?q={email}+in:email
GitHub User API:   https://api.github.com/users/{username}

Rate limits:
  - Unauthenticated: 10 search requests/min, 60 requests/hr
  - Authenticated:   30 search requests/min, 5000 requests/hr
  Set GITHUB_TOKEN in .env to raise limits.
"""
from __future__ import annotations
import asyncio
from typing import Optional

import httpx

from app.config import settings
from app.models import GitHubProfile


_BASE = "https://api.github.com"
_TIMEOUT = 10.0


def _headers() -> dict:
    h = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "EmailOSINT/2.0",
    }
    if settings.has_github:
        h["Authorization"] = f"Bearer {settings.github_token}"
    return h


async def fetch_github_profile(email: str) -> GitHubProfile:
    """
    Search GitHub for a user with the given email, then pull their profile.
    Returns a GitHubProfile (found=False if nothing is found or an error occurs).
    """
    async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
        # Step 1: Search by email
        try:
            search_resp = await client.get(
                f"{_BASE}/search/users",
                params={"q": f"{email} in:email", "per_page": 1},
                headers=_headers(),
            )
            if search_resp.status_code != 200:
                print(f"[GitHub] Search failed: {search_resp.status_code}")
                return GitHubProfile(found=False)

            search_data = search_resp.json()
            items = search_data.get("items", [])
            if not items:
                return GitHubProfile(found=False)

            username = items[0]["login"]
        except Exception as exc:
            print(f"[GitHub] Search error: {exc}")
            return GitHubProfile(found=False)

        # Step 2: Fetch full user profile
        try:
            user_resp = await client.get(
                f"{_BASE}/users/{username}",
                headers=_headers(),
            )
            if user_resp.status_code != 200:
                return GitHubProfile(found=False)

            u = user_resp.json()

            # Step 3: Fetch pinned repos (top 3 public repos by stars)
            repos_resp = await client.get(
                f"{_BASE}/users/{username}/repos",
                params={"sort": "stars", "per_page": 3, "type": "owner"},
                headers=_headers(),
            )
            top_repos = []
            if repos_resp.status_code == 200:
                for r in repos_resp.json()[:3]:
                    top_repos.append({
                        "name": r.get("name"),
                        "description": r.get("description"),
                        "stars": r.get("stargazers_count", 0),
                        "language": r.get("language"),
                        "url": r.get("html_url"),
                    })

            return GitHubProfile(
                found=True,
                username=u.get("login"),
                name=u.get("name"),
                avatar_url=u.get("avatar_url"),
                html_url=u.get("html_url"),
                bio=u.get("bio"),
                company=u.get("company", "").strip("@") if u.get("company") else None,
                location=u.get("location"),
                blog=u.get("blog") or None,
                followers=u.get("followers", 0),
                following=u.get("following", 0),
                public_repos=u.get("public_repos", 0),
                created_at=u.get("created_at"),
                updated_at=u.get("updated_at"),
                top_repos=top_repos,
            )
        except Exception as exc:
            print(f"[GitHub] Profile fetch error: {exc}")
            return GitHubProfile(found=False)
