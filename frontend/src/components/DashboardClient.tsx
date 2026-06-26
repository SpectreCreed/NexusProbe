"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2, AlertCircle, ArrowLeft, MapPin, Building2, Users, Star } from "lucide-react";

const GithubIcon = ({ className }: { className?: string }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    className={className}
  >
    <path d="M15 22v-4a4.8 4.8 0 0 0-1-3.5c3 0 6-2 6-5.5.08-1.25-.27-2.48-1-3.5.28-1.15.28-2.35 0-3.5 0 0-1 0-3 1.5-2.64-.5-5.36-.5-8 0C6 2 5 2 5 2c-.3 1.15-.3 2.35 0 3.5A5.403 5.403 0 0 0 4 9c0 3.5 3 5.5 6 5.5-.39.49-.68 1.05-.85 1.65-.17.6-.22 1.23-.15 1.85v4" />
    <path d="M9 18c-4.51 2-5-2-7-2" />
  </svg>
);
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { RadialBarChart, RadialBar, PolarAngleAxis, PieChart, Pie, Cell } from "recharts";
import { ChartContainer, ChartTooltip, ChartTooltipContent, type ChartConfig } from "@/components/ui/chart";

export default function DashboardClient({ searchId }: { searchId: string }) {
  const [status, setStatus] = useState<"pending" | "processing" | "completed" | "failed">("pending");
  const [data, setData] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  useEffect(() => {
    let interval: NodeJS.Timeout;

    const pollStatus = async () => {
      try {
        const res = await fetch(`/api/v1/search/${searchId}/status`);
        const json = await res.json();
        setStatus(json.status);

        if (json.status === "failed") {
          setError(json.error_message || "Search failed.");
          clearInterval(interval);
        } else if (json.status === "completed") {
          clearInterval(interval);
          fetchResults();
        }
      } catch (err) {
        console.error(err);
      }
    };

    const fetchResults = async () => {
      try {
        const res = await fetch(`/api/v1/search/${searchId}/results`);
        const json = await res.json();
        if (json.status === "completed" && json.results) {
          setData(json.results);
        } else {
          setError("Results not found.");
        }
      } catch (err: any) {
        setError(err.message);
      }
    };

    // Initial poll
    pollStatus();
    interval = setInterval(pollStatus, 3000);

    return () => clearInterval(interval);
  }, [searchId]);

  if (status === "failed" || error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] p-4 text-center">
        <AlertCircle className="w-12 h-12 text-destructive mb-4" />
        <h2 className="text-xl font-bold text-destructive mb-2">Scan Failed</h2>
        <p className="text-muted-foreground">{error || "Unknown error occurred."}</p>
        <Button variant="secondary" className="mt-6" onClick={() => router.push("/")}>
          <ArrowLeft className="w-4 h-4 mr-2" /> New Search
        </Button>
      </div>
    );
  }

  if (status !== "completed" || !data) {
    return (
      <div className="max-w-5xl mx-auto p-6 space-y-6">
        <div className="flex items-center gap-4 mb-8">
          <Skeleton className="w-14 h-14 rounded-2xl" />
          <div className="space-y-2">
            <Skeleton className="h-6 w-48" />
            <Skeleton className="h-4 w-32" />
          </div>
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
          <Skeleton className="h-64 rounded-xl" />
          <Skeleton className="h-64 rounded-xl lg:col-span-2" />
        </div>
        <div className="flex justify-center py-10">
          <div className="flex flex-col items-center">
            <Loader2 className="w-8 h-8 animate-spin text-indigo-500 mb-4" />
            <p className="text-muted-foreground animate-pulse">Running OSINT pipeline...</p>
          </div>
        </div>
      </div>
    );
  }

  const { risk, accounts, breaches, github, domain, gravatar } = data;
  const foundAccounts = accounts?.filter((a: any) => a.exists) || [];

  // Risk Chart Config
  const riskScore = risk?.score || 0;
  const riskColor = risk?.color === "emerald" ? "hsl(var(--chart-2))" : 
                    risk?.color === "amber" ? "hsl(var(--chart-3))" : 
                    risk?.color === "red" ? "hsl(var(--destructive))" : "hsl(var(--primary))";

  const riskChartData = [{ name: "risk", value: riskScore, fill: "var(--color-risk)" }];

  const riskChartConfig = {
    risk: {
      label: "Risk",
      color: riskColor,
    },
  } satisfies ChartConfig;

  // Exposure Chart Config
  const exposureData = [
    { name: "breaches", label: "Breaches", value: breaches?.length || 0, fill: "var(--color-breaches)" },
    { name: "accounts", label: "Accounts", value: foundAccounts.length || 0, fill: "var(--color-accounts)" },
    { name: "domain", label: "Domain Intel", value: domain ? 1 : 0, fill: "var(--color-domain)" },
    { name: "gravatar", label: "Public Profile", value: gravatar?.found ? 1 : 0, fill: "var(--color-gravatar)" },
  ].filter(d => d.value > 0);

  const exposureChartConfig = {
    breaches: {
      label: "Breaches",
      color: "hsl(var(--destructive))",
    },
    accounts: {
      label: "Accounts",
      color: "hsl(var(--chart-1))",
    },
    domain: {
      label: "Domain Intel",
      color: "hsl(var(--chart-4))",
    },
    gravatar: {
      label: "Public Profile",
      color: "hsl(var(--chart-2))",
    },
  } satisfies ChartConfig;

  return (
    <div className="max-w-5xl mx-auto p-4 md:p-6 space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8 animate-in fade-in slide-in-from-bottom-2">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-indigo-600 to-violet-700 flex items-center justify-center text-2xl font-bold text-white shadow-lg">
            {data.email?.[0]?.toUpperCase() || "?"}
          </div>
          <div>
            <h1 className="text-xl font-bold">{github?.name || gravatar?.display_name || "Intelligence Report"}</h1>
            <p className="font-mono text-muted-foreground text-sm">{data.email}</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="secondary" onClick={() => router.push("/")}><ArrowLeft className="w-4 h-4 mr-2" /> New Search</Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5 animate-in fade-in slide-in-from-bottom-4 delay-150 fill-mode-both">
        {/* Risk Score */}
        <Card className="flex flex-col items-center justify-center text-center">
          <CardHeader className="pb-2 w-full flex flex-row items-center justify-between">
            <CardTitle className="text-lg">Risk Score</CardTitle>
            {risk?.label && <Badge variant={riskScore > 50 ? "destructive" : "secondary"}>{risk.label}</Badge>}
          </CardHeader>
          <CardContent className="flex-1 flex flex-col items-center justify-center w-full">
            <ChartContainer config={riskChartConfig} className="w-[200px] h-[200px]">
              <RadialBarChart 
                innerRadius="70%" 
                outerRadius="100%" 
                data={riskChartData} 
                startAngle={180} 
                endAngle={0}
              >
                <PolarAngleAxis type="number" domain={[0, 100]} angleAxisId={0} tick={false} />
                <RadialBar background dataKey="value" cornerRadius={10} />
                <text x="50%" y="45%" textAnchor="middle" dominantBaseline="middle" className="text-4xl font-bold fill-foreground">
                  {Math.round(riskScore)}
                </text>
              </RadialBarChart>
            </ChartContainer>
          </CardContent>
        </Card>

        {/* Exposure Overview */}
        <Card className="lg:col-span-2 flex flex-col">
          <CardHeader>
            <CardTitle>Exposure Overview</CardTitle>
            <CardDescription>Breakdown of discovered digital footprints</CardDescription>
          </CardHeader>
          <CardContent className="flex-1 flex items-center justify-center">
            {exposureData.length > 0 ? (
              <div className="w-full h-[250px] flex gap-8 items-center justify-center">
                <ChartContainer config={exposureChartConfig} className="w-[250px] h-[250px]">
                  <PieChart>
                    <ChartTooltip cursor={false} content={<ChartTooltipContent hideLabel />} />
                    <Pie data={exposureData} dataKey="value" nameKey="name" innerRadius={70} strokeWidth={2} paddingAngle={2} />
                  </PieChart>
                </ChartContainer>
                <div className="flex flex-col gap-4">
                  {exposureData.map(d => (
                    <div key={d.name} className="flex items-center gap-2">
                      <span className="w-3 h-3 rounded-full" style={{ backgroundColor: exposureChartConfig[d.name as keyof typeof exposureChartConfig]?.color }}></span>
                      <span className="text-sm font-medium">{d.label}</span>
                      <span className="text-sm text-muted-foreground ml-auto">{d.value}</span>
                    </div>
                  ))}
                </div>
              </div>
            ) : (
              <div className="text-center text-muted-foreground">No significant exposures found</div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Details Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-5 animate-in fade-in slide-in-from-bottom-4 delay-300 fill-mode-both">        {/* GitHub Profile Card */}
        {github?.found ? (
          <Card className="md:col-span-2">
            <CardHeader className="pb-3 border-b">
              <div className="flex items-center gap-3">
                <GithubIcon className="w-5 h-5" />
                <div>
                  <CardTitle>GitHub Profile</CardTitle>
                  <CardDescription>Public repository and contribution data</CardDescription>
                </div>
                {github.html_url && (
                  <Button variant="outline" size="sm" className="ml-auto" asChild>
                    <a href={github.html_url} target="_blank" rel="noreferrer">
                      View Profile
                    </a>
                  </Button>
                )}
              </div>
            </CardHeader>
            <CardContent className="pt-6">
              <div className="flex flex-col md:flex-row gap-6">
                <div className="flex-shrink-0">
                  {github.avatar_url ? (
                    <img src={github.avatar_url} alt="GitHub Avatar" className="w-24 h-24 rounded-full border-4 border-muted" />
                  ) : (
                    <div className="w-24 h-24 rounded-full bg-muted flex items-center justify-center text-2xl font-bold">
                      {github.username?.[0]?.toUpperCase() || "G"}
                    </div>
                  )}
                </div>
                
                <div className="flex-1 space-y-4">
                  <div>
                    <h3 className="text-xl font-bold flex items-center gap-2">
                      {github.name || github.username} 
                      <a href={github.html_url} target="_blank" rel="noreferrer" className="text-sm font-normal text-muted-foreground hover:underline">
                        @{github.username}
                      </a>
                    </h3>
                    {github.bio && <p className="text-sm text-muted-foreground mt-1">{github.bio}</p>}
                  </div>

                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 py-3 border-y">
                    <div className="flex flex-col">
                      <span className="text-xs text-muted-foreground uppercase font-semibold">Followers</span>
                      <span className="text-lg font-bold">{github.followers?.toLocaleString() || 0}</span>
                    </div>
                    <div className="flex flex-col">
                      <span className="text-xs text-muted-foreground uppercase font-semibold">Following</span>
                      <span className="text-lg font-bold">{github.following?.toLocaleString() || 0}</span>
                    </div>
                    <div className="flex flex-col">
                      <span className="text-xs text-muted-foreground uppercase font-semibold">Public Repos</span>
                      <span className="text-lg font-bold">{github.public_repos || 0}</span>
                    </div>
                    <div className="flex flex-col">
                      <span className="text-xs text-muted-foreground uppercase font-semibold">Joined</span>
                      <span className="text-sm font-medium mt-1">{github.created_at ? new Date(github.created_at).toLocaleDateString() : 'N/A'}</span>
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-x-6 gap-y-2 text-sm">
                    {github.company && (
                      <div className="flex items-center gap-1.5 text-muted-foreground">
                        <Building2 className="w-4 h-4" />
                        <span>{github.company}</span>
                      </div>
                    )}
                    {github.location && (
                      <div className="flex items-center gap-1.5 text-muted-foreground">
                        <MapPin className="w-4 h-4" />
                        <span>{github.location}</span>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Top Repositories */}
              {github.top_repos && github.top_repos.length > 0 && (
                <div className="mt-6 pt-6 border-t">
                  <h4 className="text-sm font-semibold mb-3 flex items-center gap-2">
                    <Star className="w-4 h-4 text-yellow-500" /> Top Repositories
                  </h4>
                  <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                    {github.top_repos.map((repo: any, i: number) => (
                      <a 
                        key={i} 
                        href={repo.url} 
                        target="_blank" 
                        rel="noreferrer"
                        className="block p-3 rounded-lg border bg-card hover:bg-accent hover:text-accent-foreground transition-colors"
                      >
                        <div className="font-semibold text-sm truncate">{repo.name}</div>
                        {repo.description && (
                          <div className="text-xs text-muted-foreground line-clamp-1 mt-1">{repo.description}</div>
                        )}
                        <div className="flex items-center gap-3 mt-2 text-xs">
                          <span className="flex items-center gap-1">
                            <Star className="w-3 h-3" /> {repo.stars?.toLocaleString() || 0}
                          </span>
                          {repo.language && (
                            <span className="text-muted-foreground">{repo.language}</span>
                          )}
                        </div>
                      </a>
                    ))}
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        ) : (
          <Card className="md:col-span-2 opacity-70">
            <CardHeader className="pb-3 border-b">
              <div className="flex items-center gap-3">
                <GithubIcon className="w-5 h-5 text-muted-foreground" />
                <div>
                  <CardTitle className="text-muted-foreground">GitHub Profile</CardTitle>
                </div>
              </div>
            </CardHeader>
            <CardContent className="pt-6 flex flex-col items-center justify-center py-8">
              <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center mb-3">
                <GithubIcon className="w-6 h-6 text-muted-foreground" />
              </div>
              <p className="text-muted-foreground font-medium">No GitHub profile found</p>
              <p className="text-xs text-muted-foreground mt-1">This email does not appear to be publicly associated with any GitHub account.</p>
            </CardContent>
          </Card>
        )}

        <Card>
          <CardHeader>
            <CardTitle>Registered Accounts ({foundAccounts.length})</CardTitle>
          </CardHeader>
          <CardContent>
            {foundAccounts.length > 0 ? (
              <div className="flex flex-wrap gap-2">
                {foundAccounts.map((acc: any) => (
                  <Badge key={acc.service} variant="secondary">{acc.service}</Badge>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">No accounts found.</p>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Data Breaches ({breaches?.length || 0})</CardTitle>
          </CardHeader>
          <CardContent>
            {breaches?.length > 0 ? (
              <div className="flex flex-wrap gap-2">
                {breaches.slice(0, 10).map((b: any, i: number) => (
                  <Badge key={i} variant="destructive">{b.name || b.domain}</Badge>
                ))}
                {breaches.length > 10 && <span className="text-xs text-muted-foreground">+{breaches.length - 10} more</span>}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">No data breaches found.</p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
