"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2, AlertCircle, ArrowLeft, MapPin, Building2, Users, Star, ExternalLink, Link, Globe } from "lucide-react";

import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faGithub, faSpotify, faSnapchat, faReddit, faPinterest, faTumblr, faTwitch, faDiscord, faPaypal, faEbay, faEtsy, faWordpress, faMedium, faTiktok, faSlack, faTrello, faWhatsapp, faTelegram, faSkype, faAmazon, faApple, faGoogle, faMicrosoft, faSteam, faGitlab, faBitbucket, faStackOverflow, faQuora, faFlickr, faPatreon, faSoundcloud, faVimeoV, faDropbox, faDuolingo } from "@fortawesome/free-brands-svg-icons";

const faBrandsMap: Record<string, any> = {
  spotify: faSpotify, snapchat: faSnapchat, reddit: faReddit, pinterest: faPinterest,
  tumblr: faTumblr, twitch: faTwitch, discord: faDiscord, paypal: faPaypal, ebay: faEbay,
  etsy: faEtsy, wordpress: faWordpress, medium: faMedium, tiktok: faTiktok, slack: faSlack,
  trello: faTrello, vimeo: faVimeoV, whatsapp: faWhatsapp, telegram: faTelegram, skype: faSkype,
  amazon: faAmazon, apple: faApple, google: faGoogle, microsoft: faMicrosoft, steam: faSteam,
  gitlab: faGitlab, bitbucket: faBitbucket, stackoverflow: faStackOverflow, quora: faQuora,
  flickr: faFlickr, patreon: faPatreon, soundcloud: faSoundcloud,
  dropbox: faDropbox, duolingo: faDuolingo
};

const getPlatformIcon = (platform: string) => {
  if (!platform) return <Globe className="w-6 h-6" />;
  const p = platform.toLowerCase();

  if (p.includes('github')) return <FontAwesomeIcon icon={faGithub} className="w-6 h-6" />;
  if (p.includes('spotify')) return <FontAwesomeIcon icon={faSpotify} className="w-6 h-6" />;

  for (const [key, icon] of Object.entries(faBrandsMap)) {
    if (p.includes(key)) {
      return <FontAwesomeIcon icon={icon} className="w-6 h-6" />;
    }
  }

  return <Globe className="w-6 h-6" />;
};

import { Button, buttonVariants } from "@/components/ui/button";
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

  const { risk, accounts, breaches, github, domain, gravatar, profiles = [], photos = [], google_data } = data;

  // Use the backend-provided photos array
  const allAvatars = photos;

  return (
    <div className="max-w-6xl mx-auto p-4 md:p-6 space-y-8">
      {/* Header, Risk Score, Exposure Overview - keep your existing code */}

      {/* === PROFILE PHOTOS GRID === */}
      {allAvatars.length > 0 && (
        <div className="space-y-4">
          <h2 className="text-xl font-bold tracking-tight">Profile Photos</h2>
          <div className="flex flex-wrap gap-4">
            {allAvatars.map((av: any, idx: number) => (
              <div key={idx} className="relative group">
                <img src={av.url} alt={av.platform} className="w-20 h-20 rounded-2xl object-cover border-2 border-primary/20 shadow-sm" />
                <Badge className="absolute -bottom-2 -right-2 text-[10px] scale-90">{av.platform}</Badge>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* === GOOGLE ECOSYSTEM === */}
      {google_data?.found && (
        <div className="space-y-6">
          <div className="flex items-center gap-4">
            {google_data.avatar_url && (
              <img src={google_data.avatar_url} alt="Google Avatar" className="w-14 h-14 rounded-full border-2 border-red-500/20" />
            )}
            <div>
              <h2 className="text-2xl font-bold tracking-tight text-red-500 flex items-center gap-2">
                <Globe className="w-6 h-6" /> Google Ecosystem
              </h2>
              <div className="flex items-center gap-2 mt-1">
                {google_data.user_id && <Badge variant="secondary" className="text-xs font-mono">{google_data.user_id}</Badge>}
                {google_data.local_guide && <Badge className="bg-yellow-500 hover:bg-yellow-600 text-black text-xs"><Star className="w-3 h-3 mr-1 fill-black" /> Local Guide</Badge>}
              </div>
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card>
              <CardHeader><CardTitle className="text-lg">Active Apps</CardTitle></CardHeader>
              <CardContent>
                <div className="flex flex-wrap gap-2">
                  {google_data.active_apps?.map((app: string) => (
                    <Badge key={app} variant="outline" className="text-sm bg-red-500/10 text-red-500 border-red-500/20">{app}</Badge>
                  ))}
                </div>
              </CardContent>
            </Card>
            {google_data.maps_reviews?.length > 0 && (
              <Card>
                <CardHeader><CardTitle className="text-lg">Maps Reviews</CardTitle></CardHeader>
                <CardContent className="space-y-4">
                  {google_data.maps_reviews.map((rev: any, idx: number) => (
                    <div key={idx} className="bg-muted p-3 rounded-lg text-sm">
                      <div className="flex items-center justify-between font-semibold mb-1">
                        <span className="flex items-center gap-1"><MapPin className="w-3 h-3" /> {rev.location}</span>
                        <span className="text-yellow-500 flex items-center gap-1"><Star className="w-3 h-3 fill-yellow-500" /> {rev.rating}</span>
                      </div>
                      <p className="text-muted-foreground italic">&quot;{rev.comment}&quot;</p>
                      {rev.date && <p className="text-xs text-muted-foreground mt-2">{rev.date}</p>}
                    </div>
                  ))}
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      )}

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
                    <a href={acc.url} target="_blank" rel="noopener noreferrer" className={buttonVariants({ variant: "outline", size: "sm", className: "w-full" })}>
                      View Profile <ExternalLink className="ml-1 w-3 h-3" />
                    </a>
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