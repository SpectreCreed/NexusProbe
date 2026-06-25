"""
Google Ecosystem service — mocks or lightly fetches Google data.
Without GHunt and cookies, we provide basic placeholder logic.
"""
from __future__ import annotations
from app.models import GoogleEcosystem, GoogleReview

async def fetch_google_ecosystem(email: str) -> tuple[GoogleEcosystem | None, str | None]:
    """
    Returns (GoogleEcosystem, error_message).
    """
    # For now, we return a structured placeholder showing "no data found".
    # In a real scenario, this would invoke a scraper or GHunt.
    return GoogleEcosystem(
        found=False,
        user_id=None,
        active_apps=[],
        maps_reviews=[]
    ), None
