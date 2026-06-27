"""
XposedOrNot service — fetches detailed breach data for an email address.
Fully free API, no key required.

Uses the `breach-analytics` endpoint (not the bare `check-email` endpoint)
because that's the only one that returns per-breach detail: dates, domains,
descriptions, exposed data types, and verification/sensitivity signals.
The bare endpoint only returns a list of breach names.
"""
from __future__ import annotations
import httpx
from typing import List
from app.models import BreachEntry

XON_BASE = "https://api.xposedornot.com/v1"

# Data types that indicate a breach is genuinely high-risk to the person,
# beyond just "your email address was in a leaked list somewhere".
_SENSITIVE_DATA_MARKERS = (
    "password",
    "credit card",
    "debit card",
    "bank",
    "social security",
    "ssn",
    "passport",
    "government id",
    "national id",
    "health",
    "medical",
    "biometric",
    "pin",
    "security question",
)


def _is_sensitive(data_classes: List[str], password_risk: str | None) -> bool:
    if password_risk and password_risk.lower() in ("plaintext", "easytocrack"):
        return True
    lowered = [d.lower() for d in data_classes]
    return any(marker in d for d in lowered for marker in _SENSITIVE_DATA_MARKERS)


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
                f"{XON_BASE}/breach-analytics",
                params={"email": email},
                headers=headers,
            )

            if resp.status_code == 404:
                # No breaches found
                return [], None
            if resp.status_code == 429:
                return [], "rate_limited"

            resp.raise_for_status()
            data = resp.json()

            exposed = data.get("ExposedBreaches")
            if not exposed:
                # All-null response means email wasn't found in any breach
                return [], None

            breach_details = exposed.get("breaches_details") or []

            breaches: List[BreachEntry] = []
            for item in breach_details:
                raw_data_classes = item.get("xposed_data") or ""
                data_classes = [d.strip() for d in raw_data_classes.split(";") if d.strip()]
                password_risk = item.get("password_risk")

                xposed_date = item.get("xposed_date")
                # xposed_date is usually just a year (e.g. "2015"); normalize
                # to a sortable/display-friendly date string.
                breach_date = f"{xposed_date}-01-01" if xposed_date else None

                breaches.append(
                    BreachEntry(
                        name=item.get("breach", "Unknown"),
                        domain=item.get("domain"),
                        breach_date=breach_date,
                        added_date=None,
                        pwn_count=item.get("xposed_records"),
                        description=item.get("details") or "Data breach reported by XposedOrNot.",
                        data_classes=data_classes,
                        is_verified=str(item.get("verified", "")).lower() == "yes",
                        is_sensitive=_is_sensitive(data_classes, password_risk),
                    )
                )

            return breaches, None

    except httpx.HTTPStatusError as exc:
        return [], f"http_error_{exc.response.status_code}"
    except Exception as exc:
        print(f"[XON] Error for {email}: {exc}")
        return [], "unknown_error"