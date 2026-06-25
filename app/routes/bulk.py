"""
Bulk CSV upload and batch processing routes — Phase 2.

Endpoints:
  GET  /bulk                    — Bulk upload page
  POST /bulk/upload             — Upload CSV, kick off batch OSINT
  GET  /bulk/{batch_id}/status  — JSON status for all searches in batch
  GET  /bulk/{batch_id}         — Batch results page
  GET  /bulk/{batch_id}/report  — Consolidated JSON report download
"""
from __future__ import annotations
import csv
import io
import json
import re
from typing import List

from fastapi import APIRouter, BackgroundTasks, Request, UploadFile, File, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse, StreamingResponse
from fastapi.templating import Jinja2Templates

from app import database
from app.services.osint_runner import run_osint

router = APIRouter(prefix="/bulk", tags=["bulk"])
templates = Jinja2Templates(directory="app/templates")

EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$")
MAX_EMAILS_PER_BATCH = 25


def _extract_emails_from_csv(content: bytes) -> List[str]:
    """
    Parse a CSV file and extract valid email addresses.
    Handles single-column and multi-column CSVs.
    """
    text = content.decode("utf-8", errors="replace")
    reader = csv.reader(io.StringIO(text))
    emails: List[str] = []
    seen: set[str] = set()

    for row in reader:
        for cell in row:
            email = cell.strip().lower()
            if EMAIL_REGEX.match(email) and email not in seen:
                seen.add(email)
                emails.append(email)
                if len(emails) >= MAX_EMAILS_PER_BATCH:
                    return emails
    return emails


@router.get("", response_class=HTMLResponse)
async def bulk_page(request: Request):
    """Bulk upload landing page."""
    return templates.TemplateResponse("bulk.html", {"request": request})


@router.post("/upload")
async def bulk_upload(
    request: Request,
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
):
    """
    Accept a CSV file, extract emails, create a batch record,
    and queue an OSINT job for each email.
    Returns the batch_id for polling.
    """
    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="Only .csv files are accepted.")

    content = await file.read()
    emails = _extract_emails_from_csv(content)

    if not emails:
        raise HTTPException(
            status_code=422,
            detail="No valid email addresses found in the uploaded CSV.",
        )

    # Create search records for each email
    search_ids: List[str] = []
    for email in emails:
        record = database.create_search(user_id=None, email=email)
        search_ids.append(record["id"])
        background_tasks.add_task(run_osint, record["id"], email)

    # Create and return the batch record
    batch = database.create_batch(search_ids=search_ids, emails=emails)

    return JSONResponse({
        "batch_id": batch["id"],
        "email_count": len(emails),
        "emails": emails,
        "status": "processing",
    })


@router.get("/{batch_id}/status")
async def batch_status(batch_id: str):
    """
    Return the status of every search in the batch.
    Used for real-time progress polling from the frontend.
    """
    batch = database.get_batch(batch_id)
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found.")

    search_statuses = []
    completed = 0
    failed = 0

    for sid in batch.get("search_ids", []):
        record = database.get_search(sid)
        if not record:
            continue
        status = record.get("status", "pending")
        if status == "completed":
            completed += 1
        elif status == "failed":
            failed += 1

        risk = None
        if status == "completed" and record.get("results"):
            r = record["results"].get("risk", {})
            risk = {"score": r.get("score", 0), "label": r.get("label", "Unknown"), "color": r.get("color", "slate")}

        search_statuses.append({
            "search_id": sid,
            "email": record.get("email"),
            "status": status,
            "risk": risk,
            "error_message": record.get("error_message") if status == "failed" else None,
        })

    total = len(search_statuses)
    all_done = (completed + failed) == total

    # Mark batch as completed when all searches finish
    if all_done and batch.get("status") != "completed":
        database.update_batch(batch_id, status="completed")

    return JSONResponse({
        "batch_id": batch_id,
        "status": "completed" if all_done else "processing",
        "total": total,
        "completed": completed,
        "failed": failed,
        "progress_pct": int((completed + failed) / total * 100) if total else 0,
        "searches": search_statuses,
    })


@router.get("/{batch_id}", response_class=HTMLResponse)
async def batch_results_page(request: Request, batch_id: str):
    """Batch results dashboard page."""
    batch = database.get_batch(batch_id)
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found.")
    return templates.TemplateResponse("bulk.html", {
        "request": request,
        "batch_id": batch_id,
        "email_count": len(batch.get("emails", [])),
    })


@router.get("/{batch_id}/report")
async def batch_report_download(batch_id: str):
    """Download a consolidated JSON report for the entire batch."""
    batch = database.get_batch(batch_id)
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found.")

    consolidated = []
    for sid in batch.get("search_ids", []):
        record = database.get_search(sid)
        if record and record.get("status") == "completed":
            consolidated.append({
                "email": record.get("email"),
                "search_id": sid,
                "results": record.get("results", {}),
            })

    content = json.dumps({"batch_id": batch_id, "reports": consolidated}, indent=2, default=str)
    filename = f"osint_batch_{batch_id[:8]}.json"
    return StreamingResponse(
        io.BytesIO(content.encode()),
        media_type="application/json",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )
