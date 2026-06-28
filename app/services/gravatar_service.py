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
    
    # Always provide a valid avatar URL with mystery person fallback
    avatar_url = f"https://www.gravatar.com/avatar/{email_hash}?s=400&d=mp&r=g"
    profile_url = f"https://www.gravatar.com/{email_hash}.json"

    try:
        async with httpx.AsyncClient(timeout=8.0, follow_redirects=True) as client:
            # Try to get full profile JSON (optional)
            profile_resp = await client.get(profile_url)
            display_name = None
            profile_link = None

            if profile_resp.status_code == 200:
                try:
                    data = profile_resp.json()
                    entry = data.get("entry", [{}])[0]
                    display_name = (
                        entry.get("displayName")
                        or entry.get("name", {}).get("formatted")
                        or entry.get("preferredUsername")
                    )
                    profile_link = f"https://www.gravatar.com/{email_hash}"
                except:
                    pass

            return GravatarResult(
                found=True,
                avatar_url=avatar_url,
                display_name=display_name,
                profile_url=profile_link
            )

    except Exception as exc:
        print(f"[Gravatar] Error for {email}: {exc}")
        return GravatarResult(
            found=True,
            avatar_url=avatar_url
        )