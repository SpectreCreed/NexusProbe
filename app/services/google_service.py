"""
Google Ecosystem service — public OSINT only (no Google session auth).

Pipeline:
  1. Discover a public Gaia ID via Mojeek search for maps/contrib URLs
  2. Fetch public Maps stats/reviews via Google's preview/mas RPC
  3. Fall back to registration-only result when account exists but no public profile
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from typing import List, Optional, Tuple
from urllib.parse import quote_plus, unquote

import httpx

from app.models import GoogleEcosystem, GoogleReview

_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/125.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "en-US,en;q=0.9",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
}

_MOJEEK_URL = "https://www.mojeek.com/search?q={query}"
_DDG_URL = "https://html.duckduckgo.com/html/?q={query}"
_SIGNUP_PAGE_URL = (
    "https://accounts.google.com/signup/v2/webcreateaccount"
    "?continue=https%3A%2F%2Faccounts.google.com%2FManageAccount%3Fnc%3D1"
    "&gmb=exp&biz=false&flowName=GlifWebSignIn&flowEntry=SignUp"
)
_SIGNUP_AVAIL_URL = "https://accounts.google.com/_/signup/webusernameavailability"
_GXLU_URL = "https://mail.google.com/mail/gxlu"
_ACCOUNT_LOOKUP_URL = "https://accounts.google.com/_/lookup/accountlookup"
_MAS_URL = "https://www.google.com/locationhistory/preview/mas"

_GMAPS_STATS_PB = (
    "!1s{}!2m3!1sYE3rYc2rEsqOlwSHx534DA!7e81!15i14416!6m2!4b1!7b1!9m0!16m4!1i100!4b1!5b1!6BQ0FFU0JrVm5TVWxEenc9PQ!17m28!1m6!1m2!1i0!2i0!2m2!1i458!2i736!1m6!1m2!1i1868!2i0!2m2!1i1918!2i736!1m6!1m2!1i0!2i0!2m2!1i1918!2i20!1m6!1m2!1i0!2i716!2m2!1i1918!2i736!18m12!1m3!1d806313.5865720833!2d150.19484835!3d-34.53825215!2m3!1f0!2f0!3f0!3m2!1i1918!2i736!4f13.1"
)
_GMAPS_REVIEWS_PB = (
    "!1s{}!2m3!1s_2zAZ5CJDouBi-gPpJ7biAg!7e81!15i14416!6m2!4b1!7b1!9m0!17m28!1m6!1m2!1i0!2i0!2m2!1i530!2i1279!1m6!1m2!1i3390!2i0!2m2!1i3440!2i1279!1m6!1m2!1i0!2i0!2m2!1i3440!2i20!1m6!1m2!1i0!2i1259!2m2!1i3440!2i1279!18m15!1m3!1d2834470.167608874!2d150.05636185!3d-33.57307085!2m3!1f0!2f0!3f0!3m2!1i3440!2i1279!4f13.1!6m2!1f0!2f0!41m15!1i20!2m9!2b1!3b1!5b1!7b1!12m4!1b1!2b1!4m1!1e1!3sCAESA0VnQQ%3D%3D!7m2!1m1!1e1"
)

_GAIA_FROM_URL_RE = re.compile(r"/maps/contrib/(\d{10,})")
_MOJEEK_HREF_RE = re.compile(r'href="([^"]+)"')
_AVATAR_RE = re.compile(r"https://lh3\.googleusercontent\.com/[^\"'\\s<>]+")


async def fetch_google_ecosystem(email: str) -> tuple[GoogleEcosystem | None, str | None]:
    """
    Returns (GoogleEcosystem, error_message).
    Never returns placeholder/dummy data.
    """
    email = email.strip().lower()
    if not email or "@" not in email:
        return GoogleEcosystem(found=False), "Invalid email address."

    try:
        async with httpx.AsyncClient(follow_redirects=True) as client:
            gaia_id = await _discover_gaia_id(client, email)
            if gaia_id and _is_valid_gaia_id(gaia_id):
                avatar_url, local_guide, reviews = await _fetch_maps_intel(client, gaia_id)
                return (
                    GoogleEcosystem(
                        found=True,
                        user_id=gaia_id,
                        avatar_url=avatar_url,
                        local_guide=local_guide,
                        active_apps=[],
                        maps_reviews=reviews,
                    ),
                    None,
                )

            registered = await _check_google_registration(client, email)
            if not registered:
                return GoogleEcosystem(found=False), None

            return GoogleEcosystem(found=True), None
    except httpx.TimeoutException:
        return GoogleEcosystem(found=False), "Google lookup timed out."
    except Exception as exc:
        print(f"[Google] Error for {email}: {exc}")
        return GoogleEcosystem(found=False), str(exc)


async def _check_google_registration(client: httpx.AsyncClient, email: str) -> bool:
    """Determine whether an email is registered on Google."""
    checks = (
        _check_registration_via_signup_availability,
        _check_registration_via_gxlu,
        _check_registration_via_account_lookup,
    )
    for check in checks:
        try:
            if await check(client, email):
                return True
        except Exception as exc:
            print(f"[Google] {check.__name__} failed: {exc}")
    return False


async def _check_registration_via_gxlu(client: httpx.AsyncClient, email: str) -> bool:
    resp = await client.get(
        _GXLU_URL,
        params={"email": email},
        headers=_HEADERS,
        timeout=12.0,
    )
    return any(k.lower() == "set-cookie" for k, _ in resp.headers.multi_items())


async def _check_registration_via_signup_availability(
    client: httpx.AsyncClient,
    email: str,
) -> bool:
    """
    Holehe-style registration probe via Google's signup username availability RPC.
    Response token 'gf.wuar',2 means the email is already registered.
    """
    signup_headers = {
        **_HEADERS,
        "Accept": "*/*",
        "X-Same-Domain": "1",
        "Google-Accounts-XSRF": "1",
        "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
        "Origin": "https://accounts.google.com",
        "Referer": _SIGNUP_PAGE_URL,
    }

    page = await client.get(_SIGNUP_PAGE_URL, headers=signup_headers, timeout=15.0)
    if page.status_code != 200:
        return False

    try:
        freq = page.text.split("quot;,null,null,null,&quot;")[1].split("&quot")[0]
    except (IndexError, ValueError):
        return False

    payload = {
        "continue": "https://accounts.google.com/",
        "dsh": "",
        "hl": "en",
        "f.req": f'["{freq}","","","{email}",false]',
        "azt": "",
        "cookiesDisabled": "false",
        "deviceinfo": (
            '[null,null,null,[],null,"US",null,null,[],"GlifWebSignIn",null,'
            "[null,null,[],null,null,null,null,null,null,null,null,null,null,"
            "null,null,null,null,null,null,null,null,null,null,null,null,null,"
            '[],null,null,null,[],[]],null,null,null,null,0,null,false]'
        ),
        "gmscoreversion": "undefined",
    }

    resp = await client.post(
        _SIGNUP_AVAIL_URL,
        params={"hl": "en", "rt": "j"},
        headers=signup_headers,
        data=payload,
        timeout=15.0,
    )
    return '"gf.wuar",2' in resp.text


async def _check_registration_via_account_lookup(
    client: httpx.AsyncClient,
    email: str,
) -> bool:
    """
    Fallback registration probe.
    Google returns 403 for existing accounts and 400 for unknown ones.
    """
    username, _, domain = email.partition("@")
    if not username or not domain:
        return False

    try:
        resp = await client.post(
            _ACCOUNT_LOOKUP_URL,
            json={"username": username, "domain": domain},
            headers={
                **_HEADERS,
                "Content-Type": "application/json",
            },
            timeout=12.0,
        )
    except Exception as exc:
        print(f"[Google] accountlookup failed: {exc}")
        return False

    if resp.status_code == 403:
        return True
    if resp.status_code == 400:
        return False

    # Public calendar feed is a rare positive signal for Workspace accounts.
    try:
        cal = await client.get(
            f"https://calendar.google.com/calendar/ical/{quote_plus(email)}/public/basic.ics",
            headers=_HEADERS,
            timeout=12.0,
        )
        if cal.status_code == 200 and "BEGIN:VCALENDAR" in cal.text:
            return True
    except Exception:
        pass

    return False


async def _discover_gaia_id(client: httpx.AsyncClient, email: str) -> Optional[str]:
    """Search public web indexes for a maps/contrib URL tied to this email."""
    dork = f'site:google.com/maps/contrib "{email}"'
    search_urls = (
        _MOJEEK_URL.format(query=quote_plus(dork)),
        _DDG_URL.format(query=quote_plus(dork)),
    )

    for url in search_urls:
        try:
            resp = await client.get(url, headers=_HEADERS, timeout=15.0)
            if resp.status_code == 200:
                gaia_id = _extract_gaia_from_html(resp.text)
                if gaia_id:
                    return gaia_id
        except Exception as exc:
            print(f"[Google] Gaia search failed for {url}: {exc}")

    return None


def _is_valid_gaia_id(value: str) -> bool:
    return bool(value) and value.isdigit() and len(value) >= 10


def _extract_gaia_from_html(html: str) -> Optional[str]:
    for match in _GAIA_FROM_URL_RE.finditer(html):
        gaia_id = match.group(1)
        if _is_valid_gaia_id(gaia_id):
            return gaia_id

    for href_match in _MOJEEK_HREF_RE.finditer(html):
        href = unquote(href_match.group(1))
        gaia_match = _GAIA_FROM_URL_RE.search(href)
        if gaia_match:
            gaia_id = gaia_match.group(1)
            if _is_valid_gaia_id(gaia_id):
                return gaia_id

    return None


async def _fetch_maps_intel(
    client: httpx.AsyncClient,
    gaia_id: str,
) -> Tuple[Optional[str], bool, List[GoogleReview]]:
    """Fetch public Maps stats and reviews for a known Gaia ID."""
    stats = await _fetch_maps_stats(client, gaia_id)
    reviews = await _fetch_maps_reviews(client, gaia_id)
    avatar_url = await _fetch_maps_avatar(client, gaia_id)

    review_count = stats.get("Reviews", 0) + stats.get("Ratings", 0)
    local_guide = review_count >= 3 or stats.get("Reviews", 0) >= 1

    return avatar_url, local_guide, reviews


async def _fetch_maps_stats(client: httpx.AsyncClient, gaia_id: str) -> dict[str, int]:
    url = f"{_MAS_URL}?authuser=0&hl=en&gl=us&pb={_GMAPS_STATS_PB.format(gaia_id)}"
    try:
        resp = await client.get(url, headers=_HEADERS, timeout=20.0)
        if resp.status_code != 200 or not resp.text.startswith(")]}'"):
            return {}
        data = json.loads(resp.text[5:])
        if len(data) > 16 and data[16] and data[16][8] and data[16][8][0]:
            return {sec[6]: sec[7] for sec in data[16][8][0] if len(sec) > 7}
    except Exception as exc:
        print(f"[Google] Maps stats failed: {exc}")
    return {}


async def _fetch_maps_reviews(client: httpx.AsyncClient, gaia_id: str) -> List[GoogleReview]:
    url = f"{_MAS_URL}?authuser=0&hl=en&gl=us&pb={_GMAPS_REVIEWS_PB.format(gaia_id)}"
    try:
        resp = await client.get(url, headers=_HEADERS, timeout=20.0)
        if resp.status_code != 200 or not resp.text.startswith(")]}'"):
            return []
        data = json.loads(resp.text[5:])
        if len(data) <= 45 or not data[45] or not data[45][0]:
            return []
        return _parse_mas_reviews(data[45][0])
    except Exception as exc:
        print(f"[Google] Maps reviews failed: {exc}")
        return []


def _parse_mas_reviews(reviews_data: list) -> List[GoogleReview]:
    """Parse GHunt-style Maps review tuples from the mas RPC response."""
    reviews: List[GoogleReview] = []

    for review_data in reviews_data:
        try:
            location = review_data[4][2]
            rating = review_data[2][2][0][0]
            comment = None
            if len(review_data[2][2]) > 15 and review_data[2][2][15]:
                comment = review_data[2][2][15][0][0]

            date_str = None
            ts = review_data[2][1][3]
            if isinstance(ts, (int, float)) and ts > 0:
                date_str = datetime.fromtimestamp(ts / 1_000_000, tz=timezone.utc).strftime(
                    "%Y-%m-%d"
                )

            reviews.append(
                GoogleReview(
                    location=str(location),
                    rating=int(rating),
                    comment=comment,
                    date=date_str,
                )
            )
        except (IndexError, TypeError, ValueError):
            continue

    return reviews[:10]


async def _fetch_maps_avatar(client: httpx.AsyncClient, gaia_id: str) -> Optional[str]:
    """Best-effort avatar extraction from the public contrib page."""
    url = f"https://www.google.com/maps/contrib/{gaia_id}/reviews"
    try:
        resp = await client.get(url, headers=_HEADERS, timeout=20.0)
        if resp.status_code != 200:
            return None
    except Exception:
        return None

    for match in _AVATAR_RE.finditer(resp.text):
        avatar = match.group(0)
        if "default-user" not in avatar:
            return avatar.split("=")[0] if "=" in avatar else avatar

    matches = _AVATAR_RE.findall(resp.text)
    return matches[0].split("=")[0] if matches else None
