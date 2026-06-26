"""
XposedOrNot service — fetches breach data for an email address.
Fully free API, no key required.
"""
from __future__ import annotations
import httpx
from typing import List
from app.models import BreachEntry

XON_BASE = "https://api.xposedornot.com/v1"


async def fetch_breaches(email: str) -> tuple[List[BreachEntry], str | None]:
    """
    Returns (list_of_breaches, error_message).
    error_message is None on success.
    """
    headers = {
        "user-agent": "EmailOSINTDashboard/1.0",
    }

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(
                f"{XON_BASE}/check-email/{email}",
                headers=headers
            )

            if resp.status_code == 404:
                # No breaches found
                return [], None
            if resp.status_code == 429:
                return [], "rate_limited"

            resp.raise_for_status()
            data = resp.json()

            breaches = []
            breach_names_raw = data.get("breaches", [])
            
            breach_names = []
            for item in breach_names_raw:
                if isinstance(item, list):
                    breach_names.extend(item)
                else:
                    breach_names.append(item)
            
            # Fetch metadata for these breaches if possible (optional enhancement)
            # For now, we return basic entries
            for name in breach_names:
                breaches.append(
                    BreachEntry(
                        name=name,
                        domain=None,
                        breach_date=None,
                        added_date=None,
                        pwn_count=None,
                        description="Data breach reported by XposedOrNot.",
                        data_classes=[],
                        is_verified=True,
                        is_sensitive=False,
                    )
                )
            
            return breaches, None

    except httpx.HTTPStatusError as exc:
        return [], f"http_error_{exc.response.status_code}"
    except Exception as exc:
        print(f"[XON] Error for {email}: {exc}")
        return [], "unknown_error"
