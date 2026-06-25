"""
Domain Intelligence service — fetches WHOIS data, DNS records (MX, SPF, DMARC),
and passive subdomain enumeration via crt.sh (Phase 2).
"""
from __future__ import annotations
import asyncio
import json
from typing import Optional, List
import dns.resolver
import whois
import httpx
from app.models import DomainResult


def _safe_str(value) -> Optional[str]:
    """Safely convert any WHOIS field to a plain string."""
    if value is None:
        return None
    if isinstance(value, list):
        value = value[0] if value else None
    if value is None:
        return None
    return str(value)


def _get_whois_data(domain: str) -> dict:
    """Synchronous WHOIS lookup — wrapped in a thread via asyncio."""
    try:
        w = whois.whois(domain)
        return {
            "registrar": _safe_str(w.registrar),
            "creation_date": _safe_str(w.creation_date),
            "expiration_date": _safe_str(w.expiration_date),
            "nameservers": [str(ns) for ns in (w.name_servers or [])][:6],
        }
    except Exception as exc:
        print(f"[WHOIS] Error for {domain}: {exc}")
        return {}


def _get_mx_records(domain: str) -> List[str]:
    try:
        answers = dns.resolver.resolve(domain, "MX", lifetime=8)
        return sorted([str(r.exchange).rstrip(".") for r in answers])
    except Exception:
        return []


def _get_txt_records(domain: str) -> tuple[Optional[str], Optional[str]]:
    """Returns (spf_record, dmarc_record)."""
    spf = None
    dmarc = None
    try:
        txt_answers = dns.resolver.resolve(domain, "TXT", lifetime=8)
        for rdata in txt_answers:
            txt = "".join(part.decode() for part in rdata.strings)
            if txt.startswith("v=spf1"):
                spf = txt
    except Exception:
        pass

    try:
        dmarc_answers = dns.resolver.resolve(f"_dmarc.{domain}", "TXT", lifetime=8)
        for rdata in dmarc_answers:
            txt = "".join(part.decode() for part in rdata.strings)
            if "v=DMARC1" in txt:
                dmarc = txt
    except Exception:
        pass

    return spf, dmarc


def _get_subdomains(domain: str) -> List[str]:
    """
    Query crt.sh (certificate transparency) for known subdomains.
    Free, no API key required. Returns up to 30 unique subdomains.
    """
    try:
        url = f"https://crt.sh/?q=%.{domain}&output=json"
        with httpx.Client(timeout=12.0) as client:
            resp = client.get(url, headers={"User-Agent": "EmailOSINT/2.0"})
        if resp.status_code != 200:
            return []
        data = resp.json()
        seen: set[str] = set()
        subdomains: List[str] = []
        for entry in data:
            name = entry.get("name_value", "").strip().lower()
            for sub in name.split("\n"):
                sub = sub.strip().lstrip("*.")
                if sub and sub != domain and sub.endswith(f".{domain}") and sub not in seen:
                    seen.add(sub)
                    subdomains.append(sub)
                    if len(subdomains) >= 30:
                        return subdomains
        return subdomains
    except Exception as exc:
        print(f"[Subdomain] crt.sh error for {domain}: {exc}")
        return []


async def fetch_domain_intel(email: str) -> DomainResult:
    """Fetch full domain intelligence for the email's domain."""
    domain = email.split("@", 1)[-1].lower()
    loop = asyncio.get_event_loop()

    # Run WHOIS (blocking) in a thread pool
    whois_data = await loop.run_in_executor(None, _get_whois_data, domain)

    # Run DNS lookups + subdomain enumeration concurrently in thread pool
    mx_future = loop.run_in_executor(None, _get_mx_records, domain)
    txt_future = loop.run_in_executor(None, _get_txt_records, domain)
    sub_future = loop.run_in_executor(None, _get_subdomains, domain)

    mx_records = await mx_future
    spf, dmarc = await txt_future
    subdomains = await sub_future

    return DomainResult(
        domain=domain,
        registrar=whois_data.get("registrar"),
        creation_date=whois_data.get("creation_date"),
        expiration_date=whois_data.get("expiration_date"),
        nameservers=whois_data.get("nameservers", []),
        mx_records=mx_records,
        spf_record=spf,
        dmarc_record=dmarc,
        subdomains=subdomains,
    )
