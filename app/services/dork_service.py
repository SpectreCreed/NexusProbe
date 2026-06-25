"""
Dork Service — Phase 2.
Runs pre-defined Mojeek search queries ("dorks") to surface public mentions
of an email address. Mojeek has no bot blockades or Captchas.

Polite scraping: 0.5-second delay between requests + realistic User-Agent.
"""
from __future__ import annotations
import asyncio
import re
from typing import List
from urllib.parse import quote_plus

import httpx

from app.models import DorkResult

# Mojeek search URL
_MOJEEK_URL = "https://www.mojeek.com/search?q={query}"

_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/125.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "en-US,en;q=0.9",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
}

# Dork templates: (query_template, source_label)
_DORK_TEMPLATES = [
    ('"{email}"', "general"),
    ('site:linkedin.com "{email}"', "linkedin"),
    ('site:github.com "{email}"', "github"),
    ('site:pastebin.com "{email}"', "pastebin"),
    ('site:reddit.com "{email}"', "reddit"),
]

# Regex patterns to extract results from Mojeek HTML
_HREF_RE = re.compile(r'href="([^"]+)"')
_TITLE_RE = re.compile(r'<h2>(.*?)</h2>', re.DOTALL)
_SNIPPET_RE = re.compile(r'<p class="s">(.*?)</p>', re.DOTALL)
_TAG_RE = re.compile(r"<[^>]+>")


def _strip_tags(html: str) -> str:
    # Remove HTML tags and decode HTML entities simple replacements
    text = _TAG_RE.sub("", html)
    text = text.replace("&amp;", "&").replace("&quot;", '"').replace("&#39;", "'")
    text = text.replace("&lt;", "<").replace("&gt;", ">").replace("&#8216;", "'")
    text = text.replace("&#8217;", "'").replace("&#8220;", '"').replace("&#8221;", '"')
    return text.strip()


def _parse_mojeek_results(html: str, query: str, source: str) -> List[DorkResult]:
    """Parse Mojeek HTML response into DorkResult objects."""
    results: List[DorkResult] = []
    
    # Split by result items
    chunks = html.split('<li class="r')
    for chunk in chunks[1:]:
        # Find href
        href_match = _HREF_RE.search(chunk)
        if not href_match:
            continue
        url = href_match.group(1)
        if url.startswith("/") or "mojeek.com" in url:
            continue
            
        # Find title
        title_match = _TITLE_RE.search(chunk)
        title = _strip_tags(title_match.group(1)) if title_match else "Search Result"
        
        # Find snippet
        snippet_match = _SNIPPET_RE.search(chunk)
        snippet = _strip_tags(snippet_match.group(1)) if snippet_match else None
        
        results.append(DorkResult(
            query=query,
            title=title,
            url=url,
            snippet=snippet,
            source=source,
        ))
    return results[:5]  # Top 5 per dork


async def _run_single_dork(
    client: httpx.AsyncClient,
    email: str,
    template: str,
    source: str,
) -> List[DorkResult]:
    """Run a single dork query and return parsed results."""
    query = template.format(email=email)
    url = _MOJEEK_URL.format(query=quote_plus(query))
    try:
        resp = await client.get(url, headers=_HEADERS, timeout=12.0, follow_redirects=True)
        if resp.status_code == 200:
            return _parse_mojeek_results(resp.text, query, source)
    except Exception as exc:
        print(f"[Dork] Error for query '{query}': {exc}")
    return []


async def fetch_dork_results(email: str) -> List[DorkResult]:
    """
    Run all dork templates against the email address sequentially
    (with 0.5s delay between requests to be polite).
    Returns a deduplicated list of DorkResult objects.
    """
    all_results: List[DorkResult] = []
    seen_urls: set[str] = set()

    async with httpx.AsyncClient() as client:
        for template, source in _DORK_TEMPLATES:
            results = await _run_single_dork(client, email, template, source)
            for r in results:
                if r.url not in seen_urls:
                    seen_urls.add(r.url)
                    all_results.append(r)
            # Polite delay between queries
            await asyncio.sleep(0.5)

    return all_results

