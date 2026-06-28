from __future__ import annotations
from typing import Optional, List, Any, Dict
from pydantic import BaseModel, EmailStr
from datetime import datetime


class SearchCreate(BaseModel):
    email: EmailStr


class BreachEntry(BaseModel):
    name: str
    domain: Optional[str] = None
    breach_date: Optional[str] = None
    added_date: Optional[str] = None
    pwn_count: Optional[int] = None
    description: Optional[str] = None
    data_classes: Optional[List[str]] = []
    is_verified: bool = False
    is_sensitive: bool = False


class AccountEntry(BaseModel):
    service: str
    exists: bool
    url: Optional[str] = None
    category: Optional[str] = "other"
    # Rich fields — populated by enrichment services where available
    username: Optional[str] = None
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    followers: Optional[int] = None
    following: Optional[int] = None
    location: Optional[str] = None
    bio: Optional[str] = None
    joined_at: Optional[str] = None
    extra: Optional[Dict[str, Any]] = {}


class DomainResult(BaseModel):
    domain: str
    registrar: Optional[str] = None
    creation_date: Optional[str] = None
    expiration_date: Optional[str] = None
    mx_records: Optional[List[str]] = []
    spf_record: Optional[str] = None
    dmarc_record: Optional[str] = None
    nameservers: Optional[List[str]] = []
    subdomains: Optional[List[str]] = []  # Phase 2: crt.sh subdomain enumeration


class GravatarResult(BaseModel):
    found: bool = False
    avatar_url: Optional[str] = None
    display_name: Optional[str] = None
    profile_url: Optional[str] = None
    has_custom_avatar: bool = False  # True only if a real (non-default) photo exists


class GitHubProfile(BaseModel):
    """GitHub user profile fetched via GitHub API."""
    found: bool = False
    username: Optional[str] = None
    name: Optional[str] = None
    avatar_url: Optional[str] = None
    html_url: Optional[str] = None
    bio: Optional[str] = None
    company: Optional[str] = None
    location: Optional[str] = None
    blog: Optional[str] = None
    followers: Optional[int] = None
    following: Optional[int] = None
    public_repos: Optional[int] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    top_repos: Optional[List[Dict[str, Any]]] = []


class GoogleReview(BaseModel):
    location: str
    rating: Optional[int] = None
    date: Optional[str] = None
    comment: Optional[str] = None


class GoogleEcosystem(BaseModel):
    found: bool = False
    user_id: Optional[str] = None
    avatar_url: Optional[str] = None
    local_guide: bool = False
    active_apps: List[str] = []
    maps_reviews: List[GoogleReview] = []


class ExperienceEntry(BaseModel):
    company: str
    role: Optional[str] = None
    date_range: Optional[str] = None


class Experience(BaseModel):
    found: bool = False
    entries: List[ExperienceEntry] = []


class RiskScore(BaseModel):
    score: int  # 0-100
    label: str  # Low / Medium / High / Critical
    color: str  # CSS color class
    breakdown: Dict[str, int] = {}


class DorkResult(BaseModel):
    """Phase 2: A single result from a Google/DuckDuckGo dork query."""
    query: str
    title: str
    url: str
    snippet: Optional[str] = None
    source: Optional[str] = None  # e.g. "linkedin", "github", "pastebin", "general"


class OsintResults(BaseModel):
    email: str
    gravatar: Optional[GravatarResult] = None
    github: Optional[GitHubProfile] = None       # GitHub API enrichment
    google_data: Optional[GoogleEcosystem] = None
    experience: Optional[Experience] = None
    breaches: Optional[List[BreachEntry]] = []
    breach_count: int = 0
    accounts: Optional[List[AccountEntry]] = []
    account_count: int = 0
    domain: Optional[DomainResult] = None
    risk: Optional[RiskScore] = None
    dorks: Optional[List[DorkResult]] = []       # Phase 2: web mention results
    errors: Dict[str, str] = {}
    photos: List[Dict[str, str]] = []
    profiles: List[Dict[str, Any]] = []


class SearchRecord(BaseModel):
    id: str
    email: str
    status: str  # pending | processing | completed | failed
    results: Optional[Dict[str, Any]] = {}
    error_message: Optional[str] = None
    created_at: Optional[datetime] = None


class BatchRecord(BaseModel):
    """Phase 2: Tracks a bulk CSV email scan batch."""
    id: str
    search_ids: List[str]
    emails: List[str]
    status: str  # pending | processing | completed
    created_at: Optional[datetime] = None