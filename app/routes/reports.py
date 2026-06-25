"""
Reports routes — search history and export (JSON, PDF).
"""
from __future__ import annotations
import json
from fastapi import APIRouter, Request, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse, StreamingResponse
from fastapi.templating import Jinja2Templates
import io

from app import database

router = APIRouter()
templates = Jinja2Templates(directory="app/templates")


@router.get("/history", response_class=HTMLResponse)
async def history(request: Request):
    """User's past searches."""
    user_email = request.cookies.get("user_email")
    searches = database.get_all_searches(limit=50)
    return templates.TemplateResponse("history.html", {
        "request": request,
        "searches": searches,
        "user_email": user_email,
    })


@router.get("/export/{search_id}/json")
async def export_json(request: Request, search_id: str):
    """Export search results as a JSON file."""
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


@router.get("/export/{search_id}/pdf")
async def export_pdf(request: Request, search_id: str):
    """Generate and download a PDF report using FPDF2."""
    record = database.get_search(search_id)
    if not record or record.get("status") != "completed":
        raise HTTPException(status_code=404, detail="Results not available")

    try:
        pdf_bytes = _generate_pdf(record)
        filename = f"osint_{record['email'].replace('@', '_at_')}_{search_id[:8]}.pdf"
        return StreamingResponse(
            io.BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}"},
        )
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"PDF generation failed: {exc}")


def _generate_pdf(record: dict) -> bytes:
    """Generate a structured PDF report with FPDF2."""
    from fpdf import FPDF

    results = record.get("results", {})
    email = record.get("email", "unknown")
    risk = results.get("risk", {})

    pdf = FPDF()
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()

    # Title
    pdf.set_font("Helvetica", "B", 22)
    pdf.set_text_color(30, 30, 60)
    pdf.cell(0, 12, "Email OSINT Report", ln=True, align="C")

    pdf.set_font("Helvetica", "", 12)
    pdf.set_text_color(100, 100, 120)
    pdf.cell(0, 8, f"Target: {email}", ln=True, align="C")
    pdf.ln(5)

    # Risk Score
    _pdf_section(pdf, "Risk Assessment")
    score = risk.get("score", 0)
    label = risk.get("label", "Unknown")
    pdf.set_font("Helvetica", "B", 16)
    pdf.cell(0, 10, f"Risk Score: {score}/100 — {label}", ln=True)
    pdf.ln(3)

    # Breaches
    breaches = results.get("breaches", [])
    _pdf_section(pdf, f"Data Breaches ({len(breaches)} found)")
    if breaches:
        for b in breaches:
            pdf.set_font("Helvetica", "B", 11)
            pdf.cell(0, 7, f"• {b.get('name', 'Unknown')} ({b.get('breach_date', 'N/A')})", ln=True)
            pdf.set_font("Helvetica", "", 10)
            classes = ", ".join(b.get("data_classes", []))
            if classes:
                pdf.cell(0, 6, f"  Data exposed: {classes}", ln=True)
    else:
        pdf.set_font("Helvetica", "I", 11)
        pdf.cell(0, 7, "No breaches found.", ln=True)
    pdf.ln(3)

    # Accounts
    accounts = [a for a in results.get("accounts", []) if a.get("exists")]
    _pdf_section(pdf, f"Registered Accounts ({len(accounts)} found)")
    if accounts:
        for a in accounts:
            pdf.set_font("Helvetica", "", 11)
            pdf.cell(0, 6, f"• {a.get('service', '?')} [{a.get('category', 'other')}]", ln=True)
    else:
        pdf.set_font("Helvetica", "I", 11)
        pdf.cell(0, 7, "No accounts found.", ln=True)
    pdf.ln(3)

    # Domain
    domain = results.get("domain", {})
    if domain:
        _pdf_section(pdf, f"Domain Intelligence: {domain.get('domain', '')}")
        for field, label in [
            ("registrar", "Registrar"),
            ("creation_date", "Created"),
            ("expiration_date", "Expires"),
            ("spf_record", "SPF"),
            ("dmarc_record", "DMARC"),
        ]:
            val = domain.get(field)
            if val:
                pdf.set_font("Helvetica", "", 10)
                pdf.multi_cell(0, 6, f"{label}: {val}")
        mx = domain.get("mx_records", [])
        if mx:
            pdf.multi_cell(0, 6, f"MX Records: {', '.join(mx)}")

    return bytes(pdf.output())


def _pdf_section(pdf, title: str):
    pdf.set_font("Helvetica", "B", 13)
    pdf.set_text_color(40, 60, 140)
    pdf.cell(0, 10, title, ln=True)
    pdf.set_draw_color(40, 60, 140)
    pdf.line(pdf.get_x(), pdf.get_y(), pdf.get_x() + 180, pdf.get_y())
    pdf.ln(3)
    pdf.set_text_color(30, 30, 30)
