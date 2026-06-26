"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2, AlertCircle, ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { RadialBarChart, RadialBar, PolarAngleAxis, PieChart, Pie, Cell } from "recharts";
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart";

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

  const riskChartData = [{ name: "Risk", value: riskScore, fill: riskColor }];

  // Exposure Chart Config
  const exposureData = [
    { name: "Breaches", value: breaches?.length || 0, fill: "hsl(var(--destructive))" },
    { name: "Accounts", value: foundAccounts.length || 0, fill: "hsl(var(--chart-1))" },
    { name: "Domain Intel", value: domain ? 1 : 0, fill: "hsl(var(--chart-4))" },
    { name: "Public Profile", value: gravatar?.found ? 1 : 0, fill: "hsl(var(--chart-2))" },
  ].filter(d => d.value > 0);

  const chartConfig = {
    value: { label: "Value" },
  };

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
            <ChartContainer config={chartConfig} className="w-[200px] h-[200px]">
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
                <ChartContainer config={chartConfig} className="w-[250px] h-[250px]">
                  <PieChart>
                    <ChartTooltip cursor={false} content={<ChartTooltipContent hideLabel />} />
                    <Pie data={exposureData} dataKey="value" nameKey="name" innerRadius={70} strokeWidth={2} paddingAngle={2}>
                      {exposureData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.fill} />
                      ))}
                    </Pie>
                  </PieChart>
                </ChartContainer>
                <div className="flex flex-col gap-4">
                  {exposureData.map(d => (
                    <div key={d.name} className="flex items-center gap-2">
                      <span className="w-3 h-3 rounded-full" style={{ backgroundColor: d.fill }}></span>
                      <span className="text-sm font-medium">{d.name}</span>
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
      <div className="grid grid-cols-1 md:grid-cols-2 gap-5 animate-in fade-in slide-in-from-bottom-4 delay-300 fill-mode-both">
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
