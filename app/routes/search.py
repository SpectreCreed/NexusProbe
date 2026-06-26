"""
Search routes — handles email submission, OSINT triggering, status polling, and result rendering.
"""
from __future__ import annotations
import re
from fastapi import APIRouter, BackgroundTasks, Request, Form, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates

from app import database
from app.services.osint_runner import run_osint

router = APIRouter()
templates = Jinja2Templates(directory="app/templates")

EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$")


@router.get("/", response_class=HTMLResponse)
async def index(request: Request):
    """Landing page with search input."""
    recent = database.get_all_searches(limit=5)
    return templates.TemplateResponse("index.html", {
        "request": request,
        "recent_searches": recent,
    })


@router.post("/search", response_class=HTMLResponse)
async def submit_search(
    request: Request,
    background_tasks: BackgroundTasks,
    email: str = Form(...),
):
    """Accept an email, create a search record, kick off the background OSINT job."""
    email = email.strip().lower()

    if not EMAIL_REGEX.match(email):
        return templates.TemplateResponse("partials/_error_banner.html", {
            "request": request,
            "message": f"'{email}' is not a valid email address.",
        })

    # Create search record
    record = database.create_search(user_id=None, email=email)
    search_id = record["id"]

    # Queue background OSINT job
    background_tasks.add_task(run_osint, search_id, email)

    # Immediately return the status/loading partial that will poll for results
    return templates.TemplateResponse("partials/_status_banner.html", {
        "request": request,
        "search_id": search_id,
        "email": email,
        "status": "processing",
    })


@router.get("/search/{search_id}/status")
async def search_status(request: Request, search_id: str):
    """
    HTMX polling endpoint. Returns JSON status or the full dashboard partial
    when results are ready.
    """
    record = database.get_search(search_id)
    if not record:
        raise HTTPException(status_code=404, detail="Search not found")

    status = record.get("status", "pending")

    if status in ("pending", "processing"):
        # Still running — return the loading banner (HTMX will re-poll)
        return templates.TemplateResponse("partials/_status_banner.html", {
            "request": request,
            "search_id": search_id,
            "email": record.get("email", ""),
            "status": status,
        })

    if status == "failed":
        return templates.TemplateResponse("partials/_error_banner.html", {
            "request": request,
            "message": record.get("error_message") or "OSINT scan failed. Please try again.",
        })

    # Completed — redirect to full dashboard via HTMX header
    from fastapi import Response
    return Response(headers={"HX-Redirect": f"/search/{search_id}"})


@router.get("/search/{search_id}", response_class=HTMLResponse)
async def search_result(request: Request, search_id: str):
    """Full results dashboard page."""
    record = database.get_search(search_id)
    if not record:
        raise HTTPException(status_code=404, detail="Search not found")

    status = record.get("status", "pending")
    results = record.get("results") or {}

    return templates.TemplateResponse("dashboard.html", {
        "request": request,
        "search_id": search_id,
        "email": record.get("email", ""),
        "status": status,
        "results": results,
    })
