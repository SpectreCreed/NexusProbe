"""
Mobile API — JSON REST endpoints for the Flutter Android app.
All routes are prefixed with /api/v1/.

Authentication:
  - Pass Supabase access_token as:  Authorization: Bearer <token>
  - Falls back to cookie-based auth (web sessions) when header is absent.
  - In dev/no-Supabase mode, auth is bypassed gracefully.

Endpoints:
  POST   /api/v1/auth/login
  POST   /api/v1/auth/register
  POST   /api/v1/auth/logout

  POST   /api/v1/search
  GET    /api/v1/search/{search_id}/status
  GET    /api/v1/search/{search_id}/results
  DELETE /api/v1/search/{search_id}

  GET    /api/v1/history
  GET    /api/v1/history/recent

  GET    /api/v1/export/{search_id}/json
  GET    /api/v1/export/{search_id}/pdf
"""
from __future__ import annotations

import json
import re
import io
from typing import Optional

from fastapi import APIRouter, BackgroundTasks, Request, HTTPException, Header
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, EmailStr

from app import database
from app.config import settings
from app.services.osint_runner import run_osint

router = APIRouter(prefix="/api/v1", tags=["mobile-api"])

EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _extract_user(request: Request, authorization: Optional[str] = None) -> Optional[str]:
    """
    Try to identify the current user.
    Priority: Authorization header → cookie.
    Returns Supabase user ID string or None (guest mode).
    """
    if authorization and authorization.startswith("Bearer "):
        token = authorization.removeprefix("Bearer ").strip()
        if token and settings.has_supabase:
            try:
                client = database.get_supabase()
                user = client.auth.get_user(token)
                return str(user.user.id) if user and user.user else None
            except Exception:
                pass
    if settings.has_supabase:
        return None
    return request.cookies.get("user_email")


def _error(message: str, status_code: int = 400) -> JSONResponse:
    return JSONResponse({"success": False, "error": message}, status_code=status_code)


def _ok(data: dict = None, message: str = "ok") -> JSONResponse:
    payload = {"success": True, "message": message}
    if data is not None:
        payload.update(data)
    return JSONResponse(payload)


# ---------------------------------------------------------------------------
# Auth endpoints
# ---------------------------------------------------------------------------

class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str


@router.post("/auth/login", summary="Login with email + password")
async def api_login(body: LoginRequest):
    """Returns a Supabase access_token on success."""
    if not settings.has_supabase:
        # Dev mode: accept any credentials, return a mock token
        return _ok(
            {
                "access_token": "dev-mock-token",
                "user": {"email": body.email},
            },
            message="Logged in (dev mode)",
        )
    try:
        client = database.get_supabase()
        auth_resp = client.auth.sign_in_with_password(
            {"email": body.email, "password": body.password}
        )
        return _ok(
            {
                "access_token": auth_resp.session.access_token,
                "refresh_token": auth_resp.session.refresh_token,
                "user": {
                    "email": auth_resp.user.email,
                    "id": str(auth_resp.user.id),
                },
            },
            message="Login successful",
        )
    except Exception as exc:
        return _error("Invalid email or password.", status_code=401)


@router.post("/auth/register", summary="Register a new account")
async def api_register(body: RegisterRequest):
    if not settings.has_supabase:
        return _ok(message="Registered (dev mode). Proceed to login.")
    try:
        client = database.get_supabase()
        client.auth.sign_up({"email": body.email, "password": body.password})
        return _ok(message="Registration successful. Check your email to confirm.")
    except Exception as exc:
        return _error(str(exc), status_code=400)


@router.post("/auth/logout", summary="Invalidate the current session")
async def api_logout(authorization: Optional[str] = Header(None)):
    if settings.has_supabase and authorization and authorization.startswith("Bearer "):
        try:
            client = database.get_supabase()
            client.auth.sign_out()
        except Exception:
            pass
    return _ok(message="Logged out.")


# ---------------------------------------------------------------------------
# Search endpoints
# ---------------------------------------------------------------------------

class SearchRequest(BaseModel):
    email: str


@router.post("/search", summary="Kick off an OSINT search")
async def api_start_search(
    body: SearchRequest,
    background_tasks: BackgroundTasks,
    request: Request,
    authorization: Optional[str] = Header(None),
):
    """
    Validates the email, creates a search record, queues the OSINT job.
    Returns the search_id immediately; poll /status for progress.
    """
    email = body.email.strip().lower()

    if not EMAIL_REGEX.match(email):
        return _error(f"'{email}' is not a valid email address.")

    user_id = _extract_user(request, authorization)
    record = database.create_search(user_id=user_id, email=email)
    search_id = record["id"]

    # Queue background OSINT job (same runner used by web)
    background_tasks.add_task(run_osint, search_id, email)

    return _ok(
        {
            "search_id": search_id,
            "email": email,
            "status": "processing",
        },
        message="Search started.",
    )


@router.get("/search/{search_id}/status", summary="Poll OSINT job status")
async def api_search_status(search_id: str):
    """
    Lightweight polling endpoint.
    Returns: status (pending|processing|completed|failed), progress_pct estimate.
    """
    record = database.get_search(search_id)
    if not record:
        raise HTTPException(status_code=404, detail="Search not found")

    status = record.get("status", "pending")

    # Rough progress estimate for UI spinner
    progress_map = {
        "pending": 5,
        "processing": 50,
        "completed": 100,
        "failed": 0,
    }

    return JSONResponse(
        {
            "search_id": search_id,
            "email": record.get("email", ""),
            "status": status,
            "progress_pct": progress_map.get(status, 0),
            "error_message": record.get("error_message") if status == "failed" else None,
        }
    )


@router.get("/search/{search_id}/results", summary="Get full OSINT results")
async def api_search_results(search_id: str):
    """
    Returns the complete OSINT payload once the job is completed.
    Clients should poll /status first and only call this when status == 'completed'.
    """
    record = database.get_search(search_id)
    if not record:
        raise HTTPException(status_code=404, detail="Search not found")

    status = record.get("status", "pending")

    if status in ("pending", "processing"):
        return JSONResponse(
            {"search_id": search_id, "status": status, "results": None},
            status_code=202,
        )

    if status == "failed":
        return JSONResponse(
            {
                "search_id": search_id,
                "status": "failed",
                "error": record.get("error_message", "Unknown error"),
                "results": None,
            },
            status_code=200,
        )

    return JSONResponse(
        {
            "search_id": search_id,
            "email": record.get("email", ""),
            "status": "completed",
            "results": record.get("results") or {},
        }
    )


@router.delete("/search/{search_id}", summary="Delete a search record")
async def api_delete_search(
    search_id: str,
    request: Request,
    authorization: Optional[str] = Header(None),
):
    """Removes a search record. Only the owning user may delete their records."""
    record = database.get_search(search_id)
    if not record:
        raise HTTPException(status_code=404, detail="Search not found")

    if settings.has_supabase:
        try:
            client = database.get_supabase()
            client.table("searches").delete().eq("id", search_id).execute()
        except Exception as exc:
            return _error(f"Could not delete: {exc}", status_code=500)
    else:
        # In-memory fallback
        from app.database import _memory_store
        _memory_store["searches"] = [
            s for s in _memory_store["searches"] if s["id"] != search_id
        ]

    return _ok(message="Search deleted.")


# ---------------------------------------------------------------------------
# History endpoints
# ---------------------------------------------------------------------------

@router.get("/history", summary="Get paginated search history")
async def api_history(
    request: Request,
    authorization: Optional[str] = Header(None),
    limit: int = 50,
    offset: int = 0,
):
    """Returns the authenticated user's search history (most recent first)."""
    user_id = _extract_user(request, authorization)

    if user_id:
        searches = database.get_user_searches(user_id, limit=limit)
    else:
        # Guest mode — return all recent searches (no user filter)
        searches = database.get_all_searches(limit=limit)

    # Strip heavy results payload from list view
    slim_searches = [
        {
            "id": s.get("id"),
            "email": s.get("email"),
            "status": s.get("status"),
            "created_at": s.get("created_at"),
        }
        for s in searches
    ]

    return JSONResponse({"searches": slim_searches, "total": len(slim_searches)})


@router.get("/history/recent", summary="Get last 5 searches for home screen")
async def api_recent(
    request: Request,
    authorization: Optional[str] = Header(None),
):
    """Returns up to 5 most recent searches for the home screen carousel."""
    user_id = _extract_user(request, authorization)

    if user_id:
        searches = database.get_user_searches(user_id, limit=5)
    else:
        searches = database.get_all_searches(limit=5)

    slim = [
        {
            "id": s.get("id"),
            "email": s.get("email"),
            "status": s.get("status"),
            "created_at": s.get("created_at"),
        }
        for s in searches
    ]
    return JSONResponse({"searches": slim})


# ---------------------------------------------------------------------------
# Export endpoints
# ---------------------------------------------------------------------------

@router.get("/export/{search_id}/json", summary="Download results as JSON")
async def api_export_json(search_id: str):
    record = database.get_search(search_id)
    if not record or record.get("status") != "completed":
        raise HTTPException(status_code=404, detail="Results not available")

    content = json.dumps(record.get("results", {}), indent=2, default=str)
    filename = f"osint_{record['email'].replace('@', '_at_')}_{search_id[:8]}.json"

    return StreamingResponse(
        io.BytesIO(content.encode()),
        media_type="application/json",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@router.get("/export/{search_id}/pdf", summary="Download results as PDF")
async def api_export_pdf(search_id: str):
    record = database.get_search(search_id)
    if not record or record.get("status") != "completed":
        raise HTTPException(status_code=404, detail="Results not available")

    try:
        # Re-use the PDF generator from reports route
        from app.routes.reports import _generate_pdf
        pdf_bytes = _generate_pdf(record)
        filename = f"osint_{record['email'].replace('@', '_at_')}_{search_id[:8]}.pdf"
        return StreamingResponse(
            io.BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}"},
        )
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"PDF generation failed: {exc}")


# ---------------------------------------------------------------------------
# Bulk endpoints (Phase 2)
# ---------------------------------------------------------------------------

class BulkRequest(BaseModel):
    emails: list[str]


@router.post("/bulk", summary="Start a bulk OSINT scan")
async def api_bulk_scan(
    body: BulkRequest,
    background_tasks: BackgroundTasks,
    request: Request,
    authorization: Optional[str] = Header(None),
):
    """
    Accepts a list of emails (max 25), creates a batch, and queues OSINT jobs.
    Returns the batch_id for polling.
    """
    from app import database as db
    import re as _re
    _EMAIL_RE = _re.compile(r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$")

    emails = [e.strip().lower() for e in body.emails if _EMAIL_RE.match(e.strip().lower())]
    emails = list(dict.fromkeys(emails))[:25]  # deduplicate and cap

    if not emails:
        return _error("No valid email addresses provided.")

    user_id = _extract_user(request, authorization)

    search_ids = []
    for email in emails:
        record = db.create_search(user_id=user_id, email=email)
        search_ids.append(record["id"])
        background_tasks.add_task(run_osint, record["id"], email)

    batch = db.create_batch(search_ids=search_ids, emails=emails)
    return _ok({"batch_id": batch["id"], "email_count": len(emails), "emails": emails}, message="Bulk scan started.")


@router.get("/bulk/{batch_id}/status", summary="Poll bulk batch status")
async def api_bulk_status(batch_id: str):
    """Returns live status for all searches in the batch."""
    from app import database as db
    batch = db.get_batch(batch_id)
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found.")

    statuses = []
    completed = failed = 0
    for sid in batch.get("search_ids", []):
        rec = db.get_search(sid)
        if not rec:
            continue
        s = rec.get("status", "pending")
        if s == "completed": completed += 1
        elif s == "failed": failed += 1
        risk = None
        if s == "completed" and rec.get("results"):
            r = rec["results"].get("risk", {})
            risk = {"score": r.get("score", 0), "label": r.get("label", "Unknown")}
        statuses.append({"search_id": sid, "email": rec.get("email"), "status": s, "risk": risk})

    total = len(statuses)
    all_done = (completed + failed) == total
    return JSONResponse({
        "batch_id": batch_id,
        "status": "completed" if all_done else "processing",
        "total": total, "completed": completed, "failed": failed,
        "progress_pct": int((completed + failed) / total * 100) if total else 0,
        "searches": statuses,
    })
