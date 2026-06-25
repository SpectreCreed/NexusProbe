"""
Gravatar service — fetches avatar image URL and profile data from Gravatar.
"""
from __future__ import annotations
import hashlib
import httpx
from typing import Optional
from app.models import GravatarResult


def _md5_hash(email: str) -> str:
    return hashlib.md5(email.strip().lower().encode()).hexdigest()


async def fetch_gravatar(email: str) -> GravatarResult:
    """Check Gravatar for a profile linked to this email address."""
    email_hash = _md5_hash(email)
    profile_url = f"https://www.gravatar.com/{email_hash}.json"
    avatar_url = f"https://www.gravatar.com/avatar/{email_hash}?s=200&d=404"

    try:
        async with httpx.AsyncClient(timeout=10.0, follow_redirects=True) as client:
            # Check if avatar exists (404 means no gravatar)
            avatar_resp = await client.get(avatar_url)
            if avatar_resp.status_code == 404:
                return GravatarResult(found=False)

            # Try to get full profile JSON
            profile_resp = await client.get(profile_url)
            if profile_resp.status_code == 200:
                data = profile_resp.json()
                entry = data.get("entry", [{}])[0]
                display_name = (
                    entry.get("displayName")
                    or entry.get("name", {}).get("formatted")
                    or entry.get("preferredUsername")
                )
                return GravatarResult(
                    found=True,
                    avatar_url=f"https://www.gravatar.com/avatar/{email_hash}?s=200",
                    display_name=display_name,
                    profile_url=f"https://www.gravatar.com/{email_hash}",
                )

            # Avatar exists but no public profile JSON
            return GravatarResult(
                found=True,
                avatar_url=f"https://www.gravatar.com/avatar/{email_hash}?s=200",
            )

    except Exception as exc:
        print(f"[Gravatar] Error for {email}: {exc}")
        return GravatarResult(found=False)
