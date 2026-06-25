"""
Holehe service — checks which web services have an account associated with the email.
Calls Holehe via Python import (async wrapper around its synchronous execution).
Falls back to subprocess if import fails.
"""
from __future__ import annotations
import asyncio
import json
import subprocess
import sys
from typing import List
from app.models import AccountEntry

# Category mapping for known services
SERVICE_CATEGORIES = {
    "github": "developer", "gitlab": "developer", "bitbucket": "developer",
    "stackoverflow": "developer", "hackerrank": "developer", "replit": "developer",
    "twitter": "social", "instagram": "social", "facebook": "social",
    "tiktok": "social", "snapchat": "social", "reddit": "social",
    "pinterest": "social", "tumblr": "social", "flickr": "social",
    "linkedin": "professional", "xing": "professional", "angellist": "professional",
    "amazon": "shopping", "ebay": "shopping", "etsy": "shopping",
    "spotify": "entertainment", "netflix": "entertainment", "lastfm": "entertainment",
    "steam": "gaming", "epicgames": "gaming", "roblox": "gaming",
    "protonmail": "email", "zoho": "email",
    "wordpress": "blogging", "medium": "blogging", "substack": "blogging",
    "paypal": "finance", "coinbase": "finance", "binance": "finance",
    "dropbox": "storage", "box": "storage",
    "duolingo": "education", "coursera": "education", "udemy": "education",
}


def _get_category(service_name: str) -> str:
    return SERVICE_CATEGORIES.get(service_name.lower(), "other")


async def check_accounts(email: str) -> List[AccountEntry]:
    """Check account registrations via Holehe."""
    loop = asyncio.get_event_loop()
    results = await loop.run_in_executor(None, _run_holehe_subprocess, email)
    return results


def _run_holehe_subprocess(email: str) -> List[AccountEntry]:
    """Run holehe via subprocess and parse its JSON output."""
    try:
        result = subprocess.run(
            [r"C:\Users\chinm\AppData\Roaming\Python\Python313\Scripts\holehe.exe", email, "--only-used", "--json"],
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode != 0 and not result.stdout.strip():
            print(f"[Holehe] stderr: {result.stderr[:500]}")
            return _run_holehe_text_fallback(email)

        # Parse JSON output
        entries = []
        for line in result.stdout.strip().splitlines():
            line = line.strip()
            if not line.startswith("{"):
                continue
            try:
                item = json.loads(line)
                if item.get("exists") or item.get("rateLimit") is False:
                    entries.append(
                        AccountEntry(
                            service=item.get("name", "Unknown"),
                            exists=bool(item.get("exists", False)),
                            url=item.get("url"),
                            category=_get_category(item.get("name", "")),
                        )
                    )
            except json.JSONDecodeError:
                continue
        return entries

    except subprocess.TimeoutExpired:
        print("[Holehe] Timed out")
        return []
    except FileNotFoundError:
        print("[Holehe] Not found — is holehe installed?")
        return []
    except Exception as exc:
        print(f"[Holehe] Error: {exc}")
        return []


def _run_holehe_text_fallback(email: str) -> List[AccountEntry]:
    """Run holehe without --json flag and parse text output."""
    try:
        result = subprocess.run(
            [r"C:\Users\chinm\AppData\Roaming\Python\Python313\Scripts\holehe.exe", email, "--only-used"],
            capture_output=True,
            text=True,
            timeout=120,
        )
        entries = []
        for line in result.stdout.splitlines():
            line = line.strip()
            # Holehe marks found accounts with [+]
            if "[+]" in line:
                # Filter out the explanatory summary line
                if "Email used" in line or "Rate limit" in line:
                    continue
                parts = line.split("[+]")
                if len(parts) > 1:
                    service_part = parts[1].strip()
                    service_name = service_part.split("(")[0].strip().split(":")[0].strip()
                    if service_name:
                        entries.append(
                            AccountEntry(
                                service=service_name,
                                exists=True,
                                category=_get_category(service_name),
                            )
                        )
        return entries
    except Exception as exc:
        print(f"[Holehe fallback] Error: {exc}")
        return []
