"""
Gravatar service — fetches avatar image URL and profile data from Gravatar.
Uses the d=404 trick to detect whether a real custom photo exists.
"""
from __future__ import annotations
import hashlib
import httpx
from typing import Optional
from app.models import GravatarResult


def _md5_hash(email: str) -> str:
    return hashlib.md5(email.strip().lower().encode()).hexdigest()


async def fetch_gravatar(email: str) -> GravatarResult:
    """Check Gravatar for a profile linked to this email address.
    
    Always returns a usable avatar_url (d=mp fallback).
    Sets has_custom_avatar=True only when a real, non-default photo is found.
    """
    email_hash = _md5_hash(email)

    # d=mp: mystery-person silhouette — safe fallback for display
    avatar_url = f"https://www.gravatar.com/avatar/{email_hash}?s=400&d=mp&r=g"
    # d=404: returns HTTP 404 when no custom avatar is set — used for detection only
    check_url = f"https://www.gravatar.com/avatar/{email_hash}?s=1&d=404&r=g"
    profile_url = f"https://www.gravatar.com/{email_hash}.json"

    has_custom_avatar = False
    display_name = None
    profile_link = None

    try:
        async with httpx.AsyncClient(timeout=8.0, follow_redirects=False) as client:
            # Detect whether a real custom photo exists
            try:
                check_resp = await client.head(check_url)
                has_custom_avatar = check_resp.status_code == 200
            except Exception:
                has_custom_avatar = False

            # Try to get full profile JSON for display name
            try:
                profile_resp = await client.get(profile_url)
                if profile_resp.status_code == 200:
                    data = profile_resp.json()
                    entry = data.get("entry", [{}])[0]
                    display_name = (
                        entry.get("displayName")
                        or entry.get("name", {}).get("formatted")
                        or entry.get("preferredUsername")
                    )
                    profile_link = f"https://www.gravatar.com/{email_hash}"
            except Exception:
                pass

        return GravatarResult(
            found=True,
            avatar_url=avatar_url,
            has_custom_avatar=has_custom_avatar,
            display_name=display_name,
            profile_url=profile_link,
        )

    except Exception as exc:
        print(f"[Gravatar] Error for {email}: {exc}")
        return GravatarResult(
            found=True,
            avatar_url=avatar_url,
            has_custom_avatar=False,
        )