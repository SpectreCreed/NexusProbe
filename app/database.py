"""
Supabase client wrapper. Falls back to in-memory storage when Supabase is not configured
so the app runs fully standalone without any external dependencies.
"""
from __future__ import annotations

import uuid
import json
from datetime import datetime, timezone
from typing import Optional, Any, Dict, List

from app.config import settings

# ---------------------------------------------------------------------------
# In-memory fallback store (used when Supabase is not configured)
# ---------------------------------------------------------------------------
_memory_store: Dict[str, List[Dict]] = {
    "searches": [],
    "profiles": [],
    "reports": [],
    "watchlists": [],
    "batches": [],  # Phase 2: bulk CSV scan batches
}

_supabase_client = None


def get_supabase():
    """Return a Supabase client (lazy-initialised)."""
    global _supabase_client
    if _supabase_client is None and settings.has_supabase:
        try:
            from supabase import create_client
            _supabase_client = create_client(settings.supabase_url, settings.supabase_key)
        except Exception as exc:
            print(f"[DB] Supabase init failed: {exc}. Using in-memory store.")
    return _supabase_client


# ---------------------------------------------------------------------------
# Search helpers
# ---------------------------------------------------------------------------

def create_search(user_id: Optional[str], email: str) -> Dict:
    """Insert a new search record and return it."""
    record = {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "email": email,
        "status": "pending",
        "error_message": None,
        "results": {},
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    client = get_supabase()
    if client:
        try:
            resp = client.table("searches").insert(record).execute()
            if resp.data:
                return resp.data[0]
        except Exception as exc:
            print(f"[DB] create_search failed: {exc}")
    # Fallback
    _memory_store["searches"].append(record)
    return record


def get_search(search_id: str) -> Optional[Dict]:
    """Fetch a single search record by ID."""
    client = get_supabase()
    if client:
        try:
            resp = client.table("searches").select("*").eq("id", search_id).single().execute()
            return resp.data
        except Exception as exc:
            print(f"[DB] get_search failed: {exc}")
    # Fallback
    return next((s for s in _memory_store["searches"] if s["id"] == search_id), None)


def update_search(search_id: str, **kwargs) -> Optional[Dict]:
    """Update fields on a search record."""
    client = get_supabase()
    if client:
        try:
            resp = client.table("searches").update(kwargs).eq("id", search_id).execute()
            if resp.data:
                return resp.data[0]
        except Exception as exc:
            print(f"[DB] update_search failed: {exc}")
    # Fallback
    for record in _memory_store["searches"]:
        if record["id"] == search_id:
            record.update(kwargs)
            return record
    return None


def get_user_searches(user_id: str, limit: int = 50) -> List[Dict]:
    """Fetch recent searches for a user."""
    client = get_supabase()
    if client:
        try:
            resp = (
                client.table("searches")
                .select("id, email, status, created_at")
                .eq("user_id", user_id)
                .order("created_at", desc=True)
                .limit(limit)
                .execute()
            )
            return resp.data or []
        except Exception as exc:
            print(f"[DB] get_user_searches failed: {exc}")
    # Fallback
    return [s for s in _memory_store["searches"] if s.get("user_id") == user_id][:limit]


def get_all_searches(limit: int = 50) -> List[Dict]:
    """Fetch recent searches (guest mode — no user filter)."""
    client = get_supabase()
    if client:
        try:
            resp = (
                client.table("searches")
                .select("id, email, status, created_at")
                .order("created_at", desc=True)
                .limit(limit)
                .execute()
            )
            return resp.data or []
        except Exception as exc:
            print(f"[DB] get_all_searches failed: {exc}")
    return sorted(
        _memory_store["searches"],
        key=lambda x: x.get("created_at", ""),
        reverse=True,
    )[:limit]


# ---------------------------------------------------------------------------
# Batch helpers (Phase 2 — bulk CSV processing)
# ---------------------------------------------------------------------------

def create_batch(search_ids: List[str], emails: List[str]) -> Dict:
    """Create a new batch record grouping multiple search IDs."""
    record = {
        "id": str(uuid.uuid4()),
        "search_ids": search_ids,
        "emails": emails,
        "status": "processing",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    _memory_store["batches"].append(record)
    return record


def get_batch(batch_id: str) -> Optional[Dict]:
    """Fetch a batch record by ID."""
    return next((b for b in _memory_store["batches"] if b["id"] == batch_id), None)


def update_batch(batch_id: str, **kwargs) -> Optional[Dict]:
    """Update fields on a batch record."""
    for record in _memory_store["batches"]:
        if record["id"] == batch_id:
            record.update(kwargs)
            return record
    return None
