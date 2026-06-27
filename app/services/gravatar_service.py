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
    """Check Gravatar for a profile linked to this email address.

    Gravatar will always return *some* image for any hash if you ask it to
    (via the `d=mp` "mystery person" fallback) — that does NOT mean the
    person actually has a photo set up. We check with `d=404` first, which
    tells Gravatar to return a real 404 if there's no custom image, so we
    can tell a genuine avatar apart from the generic placeholder.
    """
    email_hash = _md5_hash(email)

    avatar_check_url = f"https://www.gravatar.com/avatar/{email_hash}?d=404"
    avatar_display_url = f"https://www.gravatar.com/avatar/{email_hash}?s=400&d=mp&r=g"
    profile_url = f"https://www.gravatar.com/{email_hash}.json"

    has_custom_avatar = False
    display_name: Optional[str] = None
    profile_link: Optional[str] = None

    try:
        async with httpx.AsyncClient(timeout=8.0, follow_redirects=True) as client:
            # A 200 here means a real custom avatar exists; 404 means it doesn't.
            avatar_resp = await client.get(avatar_check_url)
            has_custom_avatar = avatar_resp.status_code == 200

            # Profile JSON is a separate, optional signal (display name etc.)
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

    except Exception as exc:
        print(f"[Gravatar] Error for {email}: {exc}")

    # Only report "found" if there's an actual public signal: a real
    # custom photo, or a populated public profile page. A bare email
    # hash existing is not exposure — every email has one.
    found = has_custom_avatar or bool(display_name)

    return GravatarResult(
        found=found,
        avatar_url=avatar_display_url if has_custom_avatar else None,
        display_name=display_name,
        profile_url=profile_link,
        has_custom_avatar=has_custom_avatar,
    )