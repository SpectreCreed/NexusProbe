"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2, AlertCircle, ArrowLeft, MapPin, Building2, Users, Star, ExternalLink, Github, Twitter, Facebook, Instagram, Linkedin, Link, Globe } from "lucide-react";

import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faSpotify, faSnapchat, faReddit, faPinterest, faTumblr, faTwitch, faDiscord, faPaypal, faEbay, faEtsy, faWordpress, faMedium, faTiktok, faSlack, faTrello, faWhatsapp, faTelegram, faSkype, faAmazon, faApple, faGoogle, faMicrosoft, faSteam, faGitlab, faBitbucket, faStackOverflow, faQuora, faFlickr, faPatreon, faSoundcloud, faVimeoV, faAdobe, faDropbox, faChess, faDuolingo } from "@fortawesome/free-brands-svg-icons";

const faBrandsMap: Record<string, any> = {
  spotify: faSpotify, snapchat: faSnapchat, reddit: faReddit, pinterest: faPinterest,
  tumblr: faTumblr, twitch: faTwitch, discord: faDiscord, paypal: faPaypal, ebay: faEbay,
  etsy: faEtsy, wordpress: faWordpress, medium: faMedium, tiktok: faTiktok, slack: faSlack,
  trello: faTrello, vimeo: faVimeoV, whatsapp: faWhatsapp, telegram: faTelegram, skype: faSkype,
  amazon: faAmazon, apple: faApple, google: faGoogle, microsoft: faMicrosoft, steam: faSteam,
  gitlab: faGitlab, bitbucket: faBitbucket, stackoverflow: faStackOverflow, quora: faQuora,
  flickr: faFlickr, patreon: faPatreon, soundcloud: faSoundcloud, adobe: faAdobe,
  dropbox: faDropbox, chess: faChess, duolingo: faDuolingo
};

const getPlatformIcon = (platform: string) => {
  if (!platform) return <Globe className="w-6 h-6" />;
  const p = platform.toLowerCase();

  if (p.includes('github')) return <Github className="w-6 h-6" />;
  if (p.includes('twitter') || p.includes('x')) return <Twitter className="w-6 h-6" />;
  if (p.includes('facebook')) return <Facebook className="w-6 h-6" />;
  if (p.includes('instagram')) return <Instagram className="w-6 h-6" />;
  if (p.includes('linkedin')) return <Linkedin className="w-6 h-6" />;
  if (p.includes('amazon')) return <FontAwesomeIcon icon={faAmazon} className="w-6 h-6" />;
  if (p.includes('microsoft') || p.includes('office')) return <FontAwesomeIcon icon={faMicrosoft} className="w-6 h-6" />;
  if (p.includes('spotify')) return <FontAwesomeIcon icon={faSpotify} className="w-6 h-6" />;
  if (p.includes('adobe')) return <FontAwesomeIcon icon={faAdobe} className="w-6 h-6" />;

  for (const [key, icon] of Object.entries(faBrandsMap)) {
    if (p.includes(key)) {
      return <FontAwesomeIcon icon={icon} className="w-6 h-6" />;
    }
  }

  return <Globe className="w-6 h-6" />;
};

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";

export default function DashboardClient({ searchId }: { searchId: string }) {
  const [status, setStatus] = useState<"pending" | "processing" | "completed" | "failed">("pending");
  const [data, setData] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  // Keep your existing polling useEffect here...

  if (status !== "completed" || !data) {
    // Your loading skeleton...
  }

  const { risk, accounts, breaches, github, domain, gravatar, profiles = [] } = data;

  return (
    <div className="max-w-6xl mx-auto p-4 md:p-6 space-y-8">
      {/* Header, Risk Score, Exposure Overview - keep your existing code */}

      {/* === RICH ACCOUNTS SECTION === */}
      <div className="space-y-6">
        <h2 className="text-2xl font-bold tracking-tight">Registered Accounts ({profiles.length})</h2>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {profiles.length > 0 ? (
            profiles.map((acc: any, index: number) => (
              <Card key={index} className="group hover:border-primary/50 transition-all duration-200 overflow-hidden">
                <CardHeader className="pb-4">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-4">
                      <div className="w-14 h-14 rounded-xl bg-muted flex items-center justify-center text-3xl border border-border">
                        {acc.avatar_url ? (
                          <img src={acc.avatar_url} alt={acc.platform} className="w-full h-full object-cover rounded-xl" />
                        ) : (
                          getPlatformIcon(acc.platform)
                        )}
                      </div>
                      <div>
                        <CardTitle className="text-xl">{acc.platform}</CardTitle>
                        <p className="text-sm text-muted-foreground mt-0.5">{acc.name}</p>
                      </div>
                    </div>
                    <Badge variant="secondary" className="text-xs mt-1">Active</Badge>
                  </div>
                </CardHeader>

                <CardContent className="space-y-4">
                  {acc.username && (
                    <div className="text-sm font-mono bg-muted/50 px-3 py-1 rounded">@{acc.username}</div>
                  )}

                  {acc.details && (
                    <div className="grid grid-cols-2 gap-x-4 gap-y-2 text-xs text-muted-foreground">
                      {acc.details.category && <div>Category: <span className="font-medium">{acc.details.category}</span></div>}
                      {acc.details.followers && <div>Followers: <span className="font-medium">{acc.details.followers}</span></div>}
                      {acc.details.company && <div>Company: <span className="font-medium">{acc.details.company}</span></div>}
                      {acc.details.location && <div>Location: <span className="font-medium">{acc.details.location}</span></div>}
                    </div>
                  )}

                  {acc.url && (
                    <Button variant="outline" size="sm" className="w-full" asChild>
                      <a href={acc.url} target="_blank" rel="noopener noreferrer">
                        View Profile <ExternalLink className="ml-1 w-3 h-3" />
                      </a>
                    </Button>
                  )}
                </CardContent>
              </Card>
            ))
          ) : (
            <Card className="col-span-full p-12 text-center">
              <p className="text-muted-foreground">No registered accounts found for this email.</p>
            </Card>
          )}
        </div>
      </div>

      {/* Add other sections like Breaches, Domain, Google here as needed */}
    </div>
  );
}