from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Supabase
    supabase_url: str = ""
    supabase_key: str = ""


    # App
    app_secret_key: str = "change-me-in-production"
    app_debug: bool = True
    app_host: str = "0.0.0.0"
    app_port: int = 8000

    # GitHub (optional - raises rate limit from 60 to 5000 req/hr)
    github_token: Optional[str] = None
    github_access_token: Optional[str] = None
    gh_token: Optional[str] = None

    # Proxy (optional for scraping)
    http_proxy: Optional[str] = None


    @property
    def has_supabase(self) -> bool:
        return bool(self.supabase_url and self.supabase_key)



    @property
    def github_auth_token(self) -> Optional[str]:
        """Return the first configured GitHub token env var."""
        for token in (self.github_token, self.github_access_token, self.gh_token):
            if token and token.strip():
                return token.strip()
        return None

    @property
    def has_github(self) -> bool:
        return bool(self.github_auth_token)


settings = Settings()
