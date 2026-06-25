"""
FastAPI application entry point.
"""
from __future__ import annotations
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import os

from app.config import settings
from app.routes import search, auth, reports
from app.routes import api as mobile_api
from app.routes import bulk


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / shutdown lifecycle."""
    print("=" * 60)
    print("  NexusProbe")
    print("=" * 60)
    print(f"  Supabase:  {'[OK] Connected' if settings.has_supabase else '[--] Not configured (in-memory mode)'}")
    print(f"  Debug:     {settings.app_debug}")
    print("=" * 60)
    yield


app = FastAPI(
    title="NexusProbe",
    description="Open Source Intelligence platform for email address investigation.",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS — allows the Flutter mobile app (and web dev tools) to reach the API.
# In production, replace "*" with your specific origins.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # tighten in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files
static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
app.mount("/static", StaticFiles(directory=static_dir), name="static")

# Web routes (HTML / HTMX)
app.include_router(search.router)
app.include_router(auth.router)
app.include_router(reports.router)
app.include_router(bulk.router)  # Phase 2: bulk CSV scan

# Mobile JSON API (Flutter app)
app.include_router(mobile_api.router)
