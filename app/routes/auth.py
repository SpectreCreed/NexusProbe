"""
Auth routes — login, register, logout via Supabase Auth.
Falls back to a simple session-based mock when Supabase is not configured.
"""
from __future__ import annotations
from fastapi import APIRouter, Request, Form, Response
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates

from app.config import settings

router = APIRouter(prefix="/auth")
templates = Jinja2Templates(directory="app/templates")


@router.get("/login", response_class=HTMLResponse)
async def login_page(request: Request, next: str = "/"):
    return templates.TemplateResponse("auth/login.html", {
        "request": request,
        "next": next,
        "supabase_configured": settings.has_supabase,
    })


@router.post("/login", response_class=HTMLResponse)
async def login_submit(
    request: Request,
    response: Response,
    email: str = Form(...),
    password: str = Form(...),
    next: str = Form("/"),
):
    if not settings.has_supabase:
        # Dev mode: accept any credentials
        resp = RedirectResponse(url=next, status_code=303)
        resp.set_cookie("user_email", email, httponly=True, max_age=86400 * 7)
        return resp

    try:
        from app.database import get_supabase
        client = get_supabase()
        auth_resp = client.auth.sign_in_with_password({"email": email, "password": password})
        resp = RedirectResponse(url=next, status_code=303)
        resp.set_cookie("access_token", auth_resp.session.access_token, httponly=True, max_age=3600)
        resp.set_cookie("user_email", email, httponly=True, max_age=86400 * 7)
        return resp
    except Exception as exc:
        return templates.TemplateResponse("auth/login.html", {
            "request": request,
            "next": next,
            "error": "Invalid email or password.",
            "supabase_configured": settings.has_supabase,
        })


@router.get("/register", response_class=HTMLResponse)
async def register_page(request: Request):
    return templates.TemplateResponse("auth/register.html", {
        "request": request,
        "supabase_configured": settings.has_supabase,
    })


@router.post("/register", response_class=HTMLResponse)
async def register_submit(
    request: Request,
    email: str = Form(...),
    password: str = Form(...),
    confirm_password: str = Form(...),
):
    if password != confirm_password:
        return templates.TemplateResponse("auth/register.html", {
            "request": request,
            "error": "Passwords do not match.",
            "supabase_configured": settings.has_supabase,
        })

    if not settings.has_supabase:
        resp = RedirectResponse(url="/", status_code=303)
        resp.set_cookie("user_email", email, httponly=True, max_age=86400 * 7)
        return resp

    try:
        from app.database import get_supabase
        client = get_supabase()
        client.auth.sign_up({"email": email, "password": password})
        return RedirectResponse(url="/auth/login?registered=1", status_code=303)
    except Exception as exc:
        return templates.TemplateResponse("auth/register.html", {
            "request": request,
            "error": str(exc),
            "supabase_configured": settings.has_supabase,
        })


@router.get("/logout")
async def logout():
    resp = RedirectResponse(url="/", status_code=303)
    resp.delete_cookie("access_token")
    resp.delete_cookie("user_email")
    return resp
