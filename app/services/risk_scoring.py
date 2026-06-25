"""
Risk scoring service — computes an overall exposure score (0-100) from OSINT results.
"""
from __future__ import annotations
from typing import Dict, List, Optional
from app.models import RiskScore, BreachEntry, AccountEntry


def calculate_risk(
    breaches: List[BreachEntry],
    accounts: List[AccountEntry],
    has_gravatar: bool,
    has_domain_intel: bool,
) -> RiskScore:
    """
    Compute a 0-100 risk score from collected OSINT signals.

    Scoring breakdown:
    - Breaches:  up to 50 points (10 pts per breach, capped at 5)
    - Accounts:  up to 30 points (2 pts per found account, capped at 15)
    - Gravatar:  10 points (public profile increases exposure)
    - Sensitive breaches: +5 bonus points each (capped at +10)
    """
    breakdown: Dict[str, int] = {}

    # Breach score
    breach_score = min(len(breaches) * 10, 50)
    breakdown["breaches"] = breach_score

    # Sensitive breach bonus
    sensitive = sum(1 for b in breaches if b.is_sensitive)
    sensitive_score = min(sensitive * 5, 10)
    breakdown["sensitive_breaches"] = sensitive_score

    # Account score
    found_accounts = [a for a in accounts if a.exists]
    account_score = min(len(found_accounts) * 2, 30)
    breakdown["accounts"] = account_score

    # Gravatar / public profile
    gravatar_score = 10 if has_gravatar else 0
    breakdown["public_profile"] = gravatar_score

    total = breach_score + sensitive_score + account_score + gravatar_score
    total = min(total, 100)

    # Label and color
    if total <= 20:
        label, color = "Low", "emerald"
    elif total <= 45:
        label, color = "Medium", "amber"
    elif total <= 70:
        label, color = "High", "orange"
    else:
        label, color = "Critical", "red"

    return RiskScore(score=total, label=label, color=color, breakdown=breakdown)
