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
    # For now, we provide realistic placeholder data if the email is a gmail.
    # In a real scenario, this would invoke a scraper or GHunt.
    is_gmail = email.lower().endswith("@gmail.com")
    
    if is_gmail:
        return GoogleEcosystem(
            found=True,
            user_id="102345678901234567890",
            avatar_url="https://lh3.googleusercontent.com/a/default-user=s120",
            local_guide=True,
            active_apps=["Google Maps", "Google Meet", "Google Calendar", "YouTube", "Google Drive"],
            maps_reviews=[
                GoogleReview(
                    location="Starbucks",
                    rating=4,
                    date="2024-05-12",
                    comment="Great coffee but usually very crowded."
                ),
                GoogleReview(
                    location="Local Library",
                    rating=5,
                    date="2023-11-20",
                    comment="Quiet and clean, perfect for studying."
                )
            ]
        ), None

    return GoogleEcosystem(
        found=False,
        user_id=None,
        active_apps=[],
        maps_reviews=[]
    ), None
