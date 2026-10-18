"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Loader2, AlertCircle, ArrowLeft, MapPin, Building2, Users,
  Star, ExternalLink, Globe, ShieldAlert, ShieldCheck, ShieldX,
  Mail, Code2, BookOpen, Calendar, Link2, AlertTriangle,
  CheckCircle2, Server, Lock, Database, ChevronRight, Eye,
} from "lucide-react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import {
  faGithub, faSpotify, faSnapchat, faReddit, faPinterest, faTumblr,
  faTwitch, faDiscord, faPaypal, faEbay, faEtsy, faWordpress, faMedium,
  faTiktok, faSlack, faTrello, faWhatsapp, faTelegram, faSkype, faAmazon,
  faApple, faGoogle, faMicrosoft, faSteam, faGitlab, faBitbucket,
  faStackOverflow, faQuora, faFlickr, faPatreon, faSoundcloud, faVimeoV,
  faDropbox, faDuolingo,
} from "@fortawesome/free-brands-svg-icons";

import { Button, buttonVariants } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";

// ─── Platform icon map ────────────────────────────────────────────────────────
const faBrandsMap: Record<string, any> = {
  spotify: faSpotify, snapchat: faSnapchat, reddit: faReddit, pinterest: faPinterest,
  tumblr: faTumblr, twitch: faTwitch, discord: faDiscord, paypal: faPaypal, ebay: faEbay,
  etsy: faEtsy, wordpress: faWordpress, medium: faMedium, tiktok: faTiktok, slack: faSlack,
  trello: faTrello, vimeo: faVimeoV, whatsapp: faWhatsapp, telegram: faTelegram, skype: faSkype,
  amazon: faAmazon, apple: faApple, google: faGoogle, microsoft: faMicrosoft, steam: faSteam,
  gitlab: faGitlab, bitbucket: faBitbucket, stackoverflow: faStackOverflow, quora: faQuora,
  flickr: faFlickr, patreon: faPatreon, soundcloud: faSoundcloud,
  dropbox: faDropbox, duolingo: faDuolingo,
};

const getPlatformIcon = (platform: string) => {
  if (!platform) return <Globe className="w-5 h-5" />;
  const p = platform.toLowerCase();
  if (p.includes("github")) return <FontAwesomeIcon icon={faGithub} className="w-5 h-5" />;
  for (const [key, icon] of Object.entries(faBrandsMap)) {
    if (p.includes(key)) return <FontAwesomeIcon icon={icon} className="w-5 h-5" />;
  }
  return <Globe className="w-5 h-5" />;
};

// ─── Risk gauge colours ───────────────────────────────────────────────────────
const getRiskColor = (score: number) => {
  if (score >= 75) return { stroke: "#ef4444", text: "text-red-400", bg: "bg-red-500/10", border: "border-red-500/30" };
  if (score >= 50) return { stroke: "#f97316", text: "text-orange-400", bg: "bg-orange-500/10", border: "border-orange-500/30" };
  if (score >= 25) return { stroke: "#f59e0b", text: "text-amber-400", bg: "bg-amber-500/10", border: "border-amber-500/30" };
  return { stroke: "#10b981", text: "text-emerald-400", bg: "bg-emerald-500/10", border: "border-emerald-500/30" };
};

// ─── Circular Risk Gauge ──────────────────────────────────────────────────────
function RiskGauge({ score, label }: { score: number; label: string }) {
  const colors = getRiskColor(score);
  const radius = 54;
  const circumference = 2 * Math.PI * radius;
  const dashOffset = circumference - (score / 100) * circumference;

  return (
    <div className="flex flex-col items-center gap-2">
      <div className="relative w-36 h-36">
        <svg className="w-full h-full -rotate-90" viewBox="0 0 120 120">
          <circle cx="60" cy="60" r={radius} fill="none" stroke="currentColor"
            strokeWidth="10" className="text-white/5" />
          <circle cx="60" cy="60" r={radius} fill="none" stroke={colors.stroke}
            strokeWidth="10" strokeLinecap="round"
            strokeDasharray={circumference} strokeDashoffset={dashOffset}
            style={{ transition: "stroke-dashoffset 1s ease" }} />
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className={`text-3xl font-black ${colors.text}`}>{score}</span>
          <span className="text-[10px] text-muted-foreground uppercase tracking-widest">/ 100</span>
        </div>
      </div>
      <Badge className={`${colors.bg} ${colors.text} ${colors.border} border px-3 py-1 text-sm font-semibold`}>
        {label} Risk
      </Badge>
    </div>
  );
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────
function DashboardSkeleton({ email }: { email?: string }) {
  return (
    <div className="max-w-6xl mx-auto p-4 md:p-8 space-y-8 animate-pulse">
      <div className="flex items-center gap-3 text-muted-foreground text-sm">
        <Skeleton className="h-8 w-8 rounded-lg" />
        <Skeleton className="h-4 w-48" />
      </div>
      <Card className="border-white/5 bg-white/[0.03]">
        <CardContent className="p-6">
          <div className="flex flex-col md:flex-row gap-8 items-center md:items-start">
            <Skeleton className="w-36 h-36 rounded-full" />
            <div className="flex-1 space-y-3 w-full">
              <Skeleton className="h-6 w-64" />
              <Skeleton className="h-4 w-40" />
              <div className="flex gap-4 pt-2">
                <Skeleton className="h-16 w-28 rounded-xl" />
                <Skeleton className="h-16 w-28 rounded-xl" />
                <Skeleton className="h-16 w-28 rounded-xl" />
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {[1, 2, 3].map(i => (
          <Card key={i} className="border-white/5 bg-white/[0.03]">
            <CardContent className="p-5 space-y-3">
              <Skeleton className="h-5 w-32" />
              <Skeleton className="h-10 w-16" />
              <Skeleton className="h-4 w-full" />
            </CardContent>
          </Card>
        ))}
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {[1, 2, 3, 4, 5, 6].map(i => (
          <Card key={i} className="border-white/5 bg-white/[0.03]">
            <CardContent className="p-5 space-y-3">
              <div className="flex items-center gap-3">
                <Skeleton className="w-12 h-12 rounded-xl" />
                <div className="space-y-2 flex-1">
                  <Skeleton className="h-4 w-24" />
                  <Skeleton className="h-3 w-32" />
                </div>
              </div>
              <Skeleton className="h-8 w-full" />
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}

// ─── Main Component ───────────────────────────────────────────────────────────
const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8000";

export default function DashboardClient({ searchId }: { searchId: string }) {
  const [status, setStatus] = useState<"pending" | "processing" | "completed" | "failed">("pending");
  const [data, setData] = useState<any>(null);
  const [email, setEmail] = useState<string>("");
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  const fetchResults = useCallback(async () => {
    try {
      const res = await fetch(`${BACKEND_URL}/api/v1/search/${searchId}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const json = await res.json();
      setEmail(json.email || "");
      setStatus(json.status);
      if (json.status === "completed" && json.results) setData(json.results);
      if (json.status === "failed") setError(json.error_message || "Search failed.");
    } catch (e: any) {
      setError(e.message);
      setStatus("failed");
    }
  }, [searchId]);

  // Poll every 2.5 s until completed or failed
  useEffect(() => {
    fetchResults();
    const interval = setInterval(() => {
      if (status === "completed" || status === "failed") {
        clearInterval(interval);
        return;
      }
      fetchResults();
    }, 2500);
    return () => clearInterval(interval);
  }, [fetchResults, status]);

  // ─── Error / Failed ──────────────────────────────────────────────────────
  if (status === "failed") {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4 text-center px-4">
        <div className="w-16 h-16 rounded-full bg-red-500/10 flex items-center justify-center">
          <AlertCircle className="w-8 h-8 text-red-400" />
        </div>
        <h2 className="text-xl font-bold">Search Failed</h2>
        <p className="text-muted-foreground max-w-md">{error || "An unexpected error occurred."}</p>
        <Button variant="outline" onClick={() => router.push("/")} className="gap-2">
          <ArrowLeft className="w-4 h-4" /> New Search
        </Button>
      </div>
    );
  }

  // ─── Loading / Processing ────────────────────────────────────────────────
  if (status !== "completed" || !data) {
    return (
      <div className="max-w-6xl mx-auto p-4 md:p-8 space-y-6">
        <div className="flex items-center gap-3 text-indigo-400">
          <Loader2 className="w-5 h-5 animate-spin" />
          <span className="text-sm font-medium">
            {status === "pending" ? "Queuing search…" : `Running OSINT modules for ${email || searchId}…`}
          </span>
        </div>
        <DashboardSkeleton email={email} />
      </div>
    );
  }

  // ─── Data ready ──────────────────────────────────────────────────────────
  const {
    risk, breaches = [], domain, gravatar, github, google_data,
    profiles = [], real_photos = [], accounts = [],
  } = data;

  const riskColors = risk ? getRiskColor(risk.score) : null;
  const foundAccountCount = profiles.length;
  const breachCount = breaches.length;

  return (
    <div className="max-w-6xl mx-auto p-4 md:p-8 space-y-10">

      {/* ── Back button ── */}
      <button
        onClick={() => router.push("/")}
        className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors group"
      >
        <ArrowLeft className="w-4 h-4 group-hover:-translate-x-0.5 transition-transform" />
        New Search
      </button>

      {/* ═══════════════════════════════════════════════════════════════════ */}
      {/* HERO — Email + Risk Gauge + Summary Stats                          */}
      {/* ═══════════════════════════════════════════════════════════════════ */}
      <Card className="border-white/5 bg-white/[0.03] backdrop-blur-xl overflow-hidden">
        <CardContent className="p-6 md:p-8">
          <div className="flex flex-col md:flex-row gap-8 items-center">
            {/* Risk Gauge */}
            {risk && <RiskGauge score={risk.score} label={risk.label} />}

            {/* Email + Stats */}
            <div className="flex-1 space-y-4 text-center md:text-left">
              <div>
                <p className="text-xs text-muted-foreground uppercase tracking-widest mb-1">Investigating</p>
                <h1 className="text-2xl md:text-3xl font-black tracking-tight font-mono text-slate-100 break-all">
                  {data.email}
                </h1>
              </div>
              <div className="flex flex-wrap gap-3 justify-center md:justify-start">
                <StatPill
                  icon={<Eye className="w-4 h-4" />}
                  label="Accounts Found"
                  value={foundAccountCount}
                  color="text-indigo-400"
                  bg="bg-indigo-500/10"
                />
                <StatPill
                  icon={<ShieldX className="w-4 h-4" />}
                  label="Breaches"
                  value={breachCount}
                  color={breachCount > 0 ? "text-red-400" : "text-emerald-400"}
                  bg={breachCount > 0 ? "bg-red-500/10" : "bg-emerald-500/10"}
                />
                <StatPill
                  icon={<Database className="w-4 h-4" />}
                  label="Domain Intel"
                  value={domain ? "Yes" : "No"}
                  color="text-cyan-400"
                  bg="bg-cyan-500/10"
                />
              </div>
              {/* Risk breakdown badges */}
              {risk?.breakdown && Object.keys(risk.breakdown).length > 0 && (
                <div className="flex flex-wrap gap-2 justify-center md:justify-start">
                  {Object.entries(risk.breakdown).map(([k, v]) => (
                    <span key={k} className="text-xs px-2 py-0.5 rounded-full bg-white/5 text-muted-foreground">
                      {k}: <strong className="text-foreground">{String(v)}</strong>
                    </span>
                  ))}
                </div>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* ═══════════════════════════════════════════════════════════════════ */}
      {/* PROFILE PHOTOS GRID — Only real person photos                       */}
      {/* ═══════════════════════════════════════════════════════════════════ */}
      {real_photos.length > 0 && (
        <section className="space-y-4">
          <SectionHeader icon={<Eye className="w-5 h-5" />} title="Profile Photos" />
          <div className="flex flex-wrap gap-4">
            {real_photos.map((av: any, idx: number) => (
              <div key={idx} className="relative group cursor-pointer">
                <div className="w-20 h-20 rounded-2xl overflow-hidden border-2 border-white/10 shadow-lg group-hover:border-indigo-500/50 transition-all duration-200 group-hover:scale-105">
                  <img
                    src={av.url}
                    alt={av.platform}
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.currentTarget as HTMLImageElement).src = `https://ui-avatars.com/api/?name=${encodeURIComponent(av.platform)}&background=1f2937&color=6b7280&size=80`;
                    }}
                  />
                </div>
                <Badge className="absolute -bottom-2 left-1/2 -translate-x-1/2 text-[9px] px-1.5 py-0.5 bg-background border border-white/10 whitespace-nowrap">
                  {av.platform}
                </Badge>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* ═══════════════════════════════════════════════════════════════════ */}
      {/* GITHUB PROFILE CARD                                                 */}
      {/* ═══════════════════════════════════════════════════════════════════ */}
      {github?.found && (
        <section className="space-y-4">
          <SectionHeader icon={<FontAwesomeIcon icon={faGithub} className="w-5 h-5" />} title="GitHub Profile" />
          <Card className="border-white/5 bg-white/[0.03] overflow-hidden group hover:border-white/10 transition-all">
            <CardContent className="p-6">
              <div className="flex flex-col md:flex-row gap-6">
                {/* Avatar */}
                {github.avatar_url && (
                  <a href={github.html_url} target="_blank" rel="noopener noreferrer" className="shrink-0">
                    <img
                      src={github.avatar_url}
                      alt={github.username}
                      className="w-20 h-20 rounded-2xl border-2 border-white/10 hover:border-indigo-500/50 transition-colors"
                    />
                  </a>
                )}
                {/* Info */}
                <div className="flex-1 space-y-3">
                  <div className="flex items-start justify-between flex-wrap gap-2">
                    <div>
                      <h3 className="text-xl font-bold">{github.name || github.username}</h3>
                      <p className="text-sm font-mono text-muted-foreground">@{github.username}</p>
                    </div>
                    {github.html_url && (
                      <a href={github.html_url} target="_blank" rel="noopener noreferrer"
                        className={buttonVariants({ variant: "outline", size: "sm", className: "gap-1.5" })}>
                        View Profile <ExternalLink className="w-3 h-3" />
                      </a>
                    )}
                  </div>
                  {github.bio && <p className="text-sm text-muted-foreground italic">"{github.bio}"</p>}

                  {/* Stat grid */}
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                    {github.followers != null && (
                      <MiniStat icon={<Users className="w-3.5 h-3.5" />} label="Followers" value={github.followers} />
                    )}
                    {github.public_repos != null && (
                      <MiniStat icon={<Code2 className="w-3.5 h-3.5" />} label="Repos" value={github.public_repos} />
                    )}
                    {github.location && (
                      <MiniStat icon={<MapPin className="w-3.5 h-3.5" />} label="Location" value={github.location} />
                    )}
                    {github.company && (
                      <MiniStat icon={<Building2 className="w-3.5 h-3.5" />} label="Company" value={github.company} />
                    )}
                  </div>

                  {/* Extras */}
                  <div className="flex flex-wrap gap-3 text-xs text-muted-foreground">
                    {github.blog && (
                      <a href={github.blog.startsWith("http") ? github.blog : `https://${github.blog}`}
                        target="_blank" rel="noopener noreferrer"
                        className="flex items-center gap-1 hover:text-indigo-400 transition-colors">
                        <Link2 className="w-3 h-3" /> {github.blog}
                      </a>
                    )}
                    {github.created_at && (
                      <span className="flex items-center gap-1">
                        <Calendar className="w-3 h-3" /> Joined {github.created_at?.slice(0, 10)}
                      </span>
                    )}
                  </div>

                  {/* Top Repos */}
                  {github.top_repos?.length > 0 && (
                    <div className="space-y-2 pt-1">
                      <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">Top Repositories</p>
                      <div className="grid grid-cols-1 md:grid-cols-3 gap-2">
                        {github.top_repos.map((repo: any) => (
                          <a key={repo.name} href={repo.url} target="_blank" rel="noopener noreferrer"
                            className="flex flex-col gap-1 p-3 rounded-xl bg-white/5 hover:bg-white/10 border border-white/5 hover:border-indigo-500/30 transition-all text-sm">
                            <span className="font-semibold truncate">{repo.name}</span>
                            {repo.description && <span className="text-xs text-muted-foreground line-clamp-2">{repo.description}</span>}
                            <div className="flex items-center gap-2 mt-auto pt-1 text-xs text-muted-foreground">
                              {repo.language && <span className="px-1.5 py-0.5 rounded bg-white/5">{repo.language}</span>}
                              <span className="flex items-center gap-0.5"><Star className="w-3 h-3" />{repo.stars}</span>
                            </div>
                          </a>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>
        </section>
      )}

      {/* ═══════════════════════════════════════════════════════════════════ */}
      {/* GOOGLE ECOSYSTEM                                                     */}
      {/* ═══════════════════════════════════════════════════════════════════ */}
      {google_data?.found && (
        <section className="space-y-4">
          <SectionHeader icon={<FontAwesomeIcon icon={faGoogle} className="w-5 h-5" />} title="Google Ecosystem" />
          <Card className="border-white/5 bg-white/[0.03]">
            <CardContent className="p-6 space-y-4">
              <div className="flex items-center gap-4">
                {google_data.avatar_url && (
                  <img src={google_data.avatar_url} alt="Google" className="w-14 h-14 rounded-full border-2 border-red-500/20" />
                )}
                <div>
                  <p className="font-semibold">Google Account Detected</p>
                  {google_data.user_id && (
                    <p className="text-xs font-mono text-muted-foreground">{google_data.user_id}</p>
                  )}
                  <div className="flex gap-2 mt-1">
                    {google_data.local_guide && (
                      <Badge className="bg-yellow-500/10 text-yellow-400 border border-yellow-500/30 text-xs">
                        <Star className="w-3 h-3 mr-1 fill-yellow-400" /> Local Guide
                      </Badge>
                    )}
                  </div>
                </div>
              </div>
              {google_data.active_apps?.length > 0 && (
                <div>
                  <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest mb-2">Active Google Apps</p>
                  <div className="flex flex-wrap gap-2">
                    {google_data.active_apps.map((app: string) => (
                      <Badge key={app} variant="outline" className="text-xs bg-red-500/10 text-red-400 border-red-500/20">{app}</Badge>
                    ))}
                  </div>
                </div>
              )}
              {google_data.maps_reviews?.length > 0 && (
                <div>
                  <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest mb-2">Maps Reviews</p>
                  <div className="space-y-2">
                    {google_data.maps_reviews.map((rev: any, idx: number) => (
                      <div key={idx} className="p-3 rounded-xl bg-white/5 text-sm">
                        <div className="flex items-center justify-between mb-1">
                          <span className="flex items-center gap-1 font-medium"><MapPin className="w-3 h-3" />{rev.location}</span>
                          {rev.rating != null && (
                            <span className="flex items-center gap-1 text-yellow-400"><Star className="w-3 h-3 fill-yellow-400" />{rev.rating}</span>
                          )}
                        </div>
                        {rev.comment && <p className="text-muted-foreground italic text-xs">"{rev.comment}"</p>}
                        {rev.date && <p className="text-xs text-muted-foreground/60 mt-1">{rev.date}</p>}
                      </div>
                    ))}
                  </div>
                </div>
              )}
              {!google_data.active_apps?.length && !google_data.maps_reviews?.length && (
                <p className="text-sm text-muted-foreground">Google account confirmed. No public Maps or app activity found.</p>
              )}
            </CardContent>
          </Card>
        </section>
      )}

      {/* ═══════════════════════════════════════════════════════════════════ */}
      {/* REGISTERED ACCOUNTS GRID                                            */}
      {/* ═══════════════════════════════════════════════════════════════════ */}
      <section className="space-y-4">
        <SectionHeader
          icon={<Globe className="w-5 h-5" />}
          title={`Registered Accounts`}
          count={profiles.length}
        />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {profiles.length > 0 ? (
            profiles.map((acc: any, index: number) => (
              <Card
                key={index}
                className="group border-white/5 bg-white/[0.03] hover:border-white/10 hover:bg-white/[0.06] transition-all duration-200 overflow-hidden"
              >
                <CardHeader className="pb-3 pt-5 px-5">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-3">
                      {/* Avatar / Icon */}
                      <div className="w-12 h-12 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center text-muted-foreground overflow-hidden shrink-0">
                        {acc.avatar_url ? (
                          <img
                            src={acc.avatar_url}
                            alt={acc.platform}
                            className="w-full h-full object-cover"
                            onError={(e) => {
                              const el = e.currentTarget as HTMLImageElement;
                              el.style.display = "none";
                              el.parentElement!.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>`;
                            }}
                          />
                        ) : (
                          getPlatformIcon(acc.platform)
                        )}
                      </div>
                      <div>
                        <CardTitle className="text-base leading-tight">{acc.platform}</CardTitle>
                        {acc.details?.category && (
                          <p className="text-xs text-muted-foreground capitalize">{acc.details.category}</p>
                        )}
                      </div>
                    </div>
                    <Badge variant="secondary" className="text-[10px] shrink-0 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                      <CheckCircle2 className="w-2.5 h-2.5 mr-1" />Active
                    </Badge>
                  </div>
                </CardHeader>

                <CardContent className="px-5 pb-5 space-y-3">
                  {acc.username && (
                    <div className="text-xs font-mono bg-white/5 px-3 py-1.5 rounded-lg text-muted-foreground">
                      @{acc.username}
                    </div>
                  )}

                  {acc.details && (
                    <div className="grid grid-cols-2 gap-x-3 gap-y-1.5 text-xs text-muted-foreground">
                      {acc.details.followers != null && (
                        <div className="flex items-center gap-1">
                          <Users className="w-3 h-3" />
                          <span>{acc.details.followers.toLocaleString()} followers</span>
                        </div>
                      )}
                      {acc.details.company && (
                        <div className="flex items-center gap-1">
                          <Building2 className="w-3 h-3" />
                          <span className="truncate">{acc.details.company}</span>
                        </div>
                      )}
                      {acc.details.location && (
                        <div className="flex items-center gap-1">
                          <MapPin className="w-3 h-3" />
                          <span className="truncate">{acc.details.location}</span>
                        </div>
                      )}
                      {acc.details.public_repos != null && (
                        <div className="flex items-center gap-1">
                          <Code2 className="w-3 h-3" />
                          <span>{acc.details.public_repos} repos</span>
                        </div>
                      )}
                      {acc.details.type && acc.details.type !== "Registered" && (
                        <div className="col-span-2 text-xs text-indigo-400">{acc.details.type}</div>
                      )}
                    </div>
                  )}

                  {acc.url && (
                    <a
                      href={acc.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className={buttonVariants({ variant: "outline", size: "sm", className: "w-full text-xs gap-1.5 mt-1" })}
                    >
                      View Profile <ExternalLink className="w-3 h-3" />
                    </a>
                  )}
                </CardContent>
              </Card>
            ))
          ) : (
            <Card className="col-span-full border-white/5 bg-white/[0.03]">
              <CardContent className="p-12 text-center">
                <Globe className="w-10 h-10 text-muted-foreground/30 mx-auto mb-3" />
                <p className="text-muted-foreground">No registered accounts found for this email.</p>
              </CardContent>
            </Card>
          )}
        </div>
      </section>

      {/* ═══════════════════════════════════════════════════════════════════ */}
      {/* DATA BREACHES                                                        */}
      {/* ═══════════════════════════════════════════════════════════════════ */}
      <section className="space-y-4">
        <SectionHeader
          icon={<ShieldX className="w-5 h-5 text-red-400" />}
          title="Data Breaches"
          count={breachCount}
          countColor={breachCount > 0 ? "bg-red-500/20 text-red-400" : undefined}
        />
        {breaches.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {breaches.map((b: any, idx: number) => (
              <Card key={idx} className="border-red-500/10 bg-red-500/[0.03] hover:border-red-500/20 transition-all">
                <CardContent className="p-5 space-y-3">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="font-semibold">{b.name}</p>
                      {b.domain && <p className="text-xs text-muted-foreground">{b.domain}</p>}
                    </div>
                    <div className="text-right shrink-0">
                      {b.breach_date && (
                        <Badge variant="outline" className="text-xs border-red-500/20 text-red-400">
                          {b.breach_date.slice(0, 10)}
                        </Badge>
                      )}
                    </div>
                  </div>
                  {b.data_classes?.length > 0 && (
                    <div className="flex flex-wrap gap-1">
                      {b.data_classes.map((dc: string) => (
                        <span key={dc} className="text-[10px] px-2 py-0.5 rounded-full bg-red-500/10 text-red-300 border border-red-500/10">
                          {dc}
                        </span>
                      ))}
                    </div>
                  )}
                  {b.pwn_count && (
                    <p className="text-xs text-muted-foreground">
                      {b.pwn_count.toLocaleString()} accounts affected
                    </p>
                  )}
                </CardContent>
              </Card>
            ))}
          </div>
        ) : (
          <Card className="border-emerald-500/10 bg-emerald-500/[0.03]">
            <CardContent className="p-6 flex items-center gap-3">
              <ShieldCheck className="w-8 h-8 text-emerald-400 shrink-0" />
              <div>
                <p className="font-semibold text-emerald-400">No Breaches Found</p>
                <p className="text-sm text-muted-foreground">This email was not found in any known data breaches.</p>
              </div>
            </CardContent>
          </Card>
        )}
      </section>

      {/* ═══════════════════════════════════════════════════════════════════ */}
      {/* DOMAIN INTELLIGENCE                                                  */}
      {/* ═══════════════════════════════════════════════════════════════════ */}
      {domain && (
        <section className="space-y-4">
          <SectionHeader icon={<Server className="w-5 h-5 text-cyan-400" />} title="Domain Intelligence" />
          <Card className="border-white/5 bg-white/[0.03]">
            <CardContent className="p-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Left: WHOIS */}
                <div className="space-y-3">
                  <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">WHOIS</p>
                  <div className="space-y-2 text-sm">
                    <DomainRow label="Domain" value={domain.domain} mono />
                    <DomainRow label="Registrar" value={domain.registrar} />
                    <DomainRow label="Created" value={domain.creation_date?.slice(0, 10)} />
                    <DomainRow label="Expires" value={domain.expiration_date?.slice(0, 10)} />
                    {domain.nameservers?.length > 0 && (
                      <DomainRow label="Nameservers" value={domain.nameservers.join(", ")} mono />
                    )}
                  </div>
                </div>
                {/* Right: Email security */}
                <div className="space-y-3">
                  <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">Email Security</p>
                  <div className="space-y-2 text-sm">
                    <SecurityRow label="SPF" value={domain.spf_record} />
                    <SecurityRow label="DMARC" value={domain.dmarc_record} />
                    {domain.mx_records?.length > 0 && (
                      <div>
                        <p className="text-xs text-muted-foreground mb-1">MX Records</p>
                        {domain.mx_records.map((mx: string) => (
                          <p key={mx} className="text-xs font-mono text-cyan-300/80 truncate">{mx}</p>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </section>
      )}

      {/* ─── Ethical Disclaimer ─────────────────────────────────────────── */}
      <footer className="border-t border-white/5 pt-8 pb-4 text-center space-y-2">
        <div className="flex items-center justify-center gap-2 text-amber-500/70">
          <AlertTriangle className="w-4 h-4" />
          <p className="text-xs font-semibold uppercase tracking-wider">Ethical Use Only</p>
        </div>
        <p className="text-xs text-muted-foreground/60 max-w-xl mx-auto leading-relaxed">
          NexusProbe collects only publicly available data. Users are responsible for compliance with applicable laws.
          This tool must not be used for stalking, harassment, or any unlawful surveillance activity.
        </p>
      </footer>
    </div>
  );
}

// ─── Sub-components ───────────────────────────────────────────────────────────

function SectionHeader({ icon, title, count, countColor }: {
  icon: React.ReactNode; title: string; count?: number; countColor?: string;
}) {
  return (
    <div className="flex items-center gap-3">
      <div className="text-muted-foreground">{icon}</div>
      <h2 className="text-lg font-bold tracking-tight">{title}</h2>
      {count != null && (
        <span className={`text-xs px-2 py-0.5 rounded-full font-semibold ${countColor ?? "bg-white/10 text-muted-foreground"}`}>
          {count}
        </span>
      )}
    </div>
  );
}

function StatPill({ icon, label, value, color, bg }: {
  icon: React.ReactNode; label: string; value: number | string; color: string; bg: string;
}) {
  return (
    <div className={`flex items-center gap-2.5 px-4 py-2.5 rounded-xl ${bg} border border-white/5`}>
      <div className={color}>{icon}</div>
      <div>
        <p className={`text-lg font-black leading-none ${color}`}>{value}</p>
        <p className="text-[10px] text-muted-foreground mt-0.5">{label}</p>
      </div>
    </div>
  );
}

function MiniStat({ icon, label, value }: { icon: React.ReactNode; label: string; value: any }) {
  return (
    <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
      <span className="shrink-0">{icon}</span>
      <span className="truncate" title={String(value)}>{String(value)}</span>
    </div>
  );
}

function DomainRow({ label, value, mono }: { label: string; value?: string | null; mono?: boolean }) {
  if (!value) return null;
  return (
    <div className="flex items-start justify-between gap-2">
      <span className="text-muted-foreground shrink-0">{label}</span>
      <span className={`text-right truncate max-w-[60%] ${mono ? "font-mono text-xs text-cyan-300/80" : ""}`}>{value}</span>
    </div>
  );
}

function SecurityRow({ label, value }: { label: string; value?: string | null }) {
  const present = Boolean(value);
  return (
    <div className="flex items-center gap-2">
      {present
        ? <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
        : <ShieldAlert className="w-3.5 h-3.5 text-red-400 shrink-0" />}
      <span className="text-muted-foreground">{label}</span>
      <span className={`ml-auto text-xs ${present ? "text-emerald-400" : "text-red-400"}`}>
        {present ? "Configured" : "Missing"}
      </span>
    </div>
  );
}