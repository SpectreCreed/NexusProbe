"""
Holehe service - checks which web services have an account associated with the email.
Runs Holehe in a worker thread because the CLI is synchronous.
"""
from __future__ import annotations

import asyncio
import json
import os
import shutil
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


def _holehe_base_command() -> List[str]:
    """Resolve Holehe without relying on a user-specific Windows path."""
    configured = os.environ.get("HOLEHE_BIN")
    if configured:
        return [configured]

    executable = shutil.which("holehe") or shutil.which("holehe.exe")
    if executable:
        return [executable]

    return [
        sys.executable, 
        "-c", 
        "import sys; from holehe.core import main; sys.exit(main())"
    ]


async def check_accounts(email: str) -> List[AccountEntry]:
    """Check account registrations via Holehe."""
    loop = asyncio.get_event_loop()
    results = await loop.run_in_executor(None, _run_holehe_subprocess, email)
    return results


def _run_holehe_subprocess(email: str) -> List[AccountEntry]:
    """Run holehe via subprocess and parse its JSON output."""
    command = [*_holehe_base_command(), email, "--only-used", "--json"]
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode != 0 and not result.stdout.strip():
            print(f"[Holehe] stderr: {result.stderr[:500]}")
            return _run_holehe_text_fallback(email)

        entries = []
        for line in result.stdout.strip().splitlines():
            line = line.strip()
            if not line.startswith("{"):
                continue
            try:
                item = json.loads(line)
                if item.get("exists") or item.get("rateLimit") is False:
                    service_name = item.get("name", "Unknown")
                    entries.append(
                        AccountEntry(
                            service=service_name,
                            exists=bool(item.get("exists", False)),
                            url=item.get("url"),
                            category=_get_category(service_name),
                        )
                    )
            except json.JSONDecodeError:
                continue
        return entries

    except subprocess.TimeoutExpired:
        print("[Holehe] Timed out")
        return []
    except FileNotFoundError:
        print("[Holehe] Not found - install holehe or set HOLEHE_BIN")
        return []
    except Exception as exc:
        print(f"[Holehe] Error: {exc}")
        return []


def _run_holehe_text_fallback(email: str) -> List[AccountEntry]:
    """Run holehe without --json flag and parse text output."""
    command = [*_holehe_base_command(), email, "--only-used"]
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=120,
        )
        entries = []
        for line in result.stdout.splitlines():
            line = line.strip()
            if "[+]" in line:
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