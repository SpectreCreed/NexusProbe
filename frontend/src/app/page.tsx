import SearchForm from "@/components/SearchForm";
import { Lock, Globe, Search, AlertTriangle } from "lucide-react";
import Link from "next/link";

export default async function Home() {
  return (
    <main className="flex-1 flex flex-col items-center justify-start pt-16">
      {/* Hero Section */}
      <section className="relative flex flex-col items-center justify-center min-h-[50vh] text-center px-4 w-full max-w-5xl overflow-hidden">
        {/* Ambient glows */}
        <div className="absolute top-1/3 left-1/4 w-80 h-80 rounded-full bg-violet-600/5 blur-3xl pointer-events-none"></div>
        <div className="absolute top-1/3 right-1/4 w-80 h-80 rounded-full bg-cyan-600/5 blur-3xl pointer-events-none"></div>

        {/* Badge */}
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-indigo-500/10 border border-indigo-500/25 text-indigo-400 text-sm font-medium mb-6 animate-in fade-in slide-in-from-bottom-4">
          <span className="w-2 h-2 rounded-full bg-indigo-400 animate-pulse"></span>
          Open Source Intelligence Platform
        </div>

        {/* Headline */}
        <h1 className="text-5xl md:text-7xl font-black leading-tight tracking-tight mb-4 animate-in fade-in slide-in-from-bottom-4 delay-150 fill-mode-both">
          <span className="text-slate-100">Uncover</span><br/>
          <span className="bg-clip-text text-transparent bg-gradient-to-r from-indigo-400 to-cyan-400">Digital Footprints</span>
        </h1>

        <p className="text-muted-foreground text-lg md:text-xl max-w-2xl mx-auto mb-10 leading-relaxed animate-in fade-in slide-in-from-bottom-4 delay-300 fill-mode-both">
          Transform any email address into a comprehensive intelligence profile.
          Discover breaches, registered accounts, domain intelligence, and social footprints.
        </p>

        {/* Search Box */}
        <div className="w-full animate-in fade-in slide-in-from-bottom-4 delay-500 fill-mode-both">
          <SearchForm />
          <p className="text-muted-foreground/60 text-xs mt-3">
            By using this tool you agree to use it for ethical, legal purposes only.
          </p>
        </div>
      </section>

      {/* Feature Cards */}
      <section className="max-w-5xl w-full mx-auto px-4 py-16 animate-in fade-in delay-700 fill-mode-both">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
          <FeatureCard 
            icon={<Lock className="w-5 h-5" />} 
            color="text-red-400" 
            bg="bg-red-500/15" 
            hoverBg="group-hover:bg-red-500/25"
            title="Data Breaches"
            description="XposedOrNot integration to surface known breach exposures with dates and data types."
          />
          <FeatureCard 
            icon={<Globe className="w-5 h-5" />} 
            color="text-indigo-400" 
            bg="bg-indigo-500/15" 
            hoverBg="group-hover:bg-indigo-500/25"
            title="Registered Accounts"
            description="Holehe checks 100+ web services for active registrations using the email."
          />
          <FeatureCard 
            icon={<Search className="w-5 h-5" />} 
            color="text-cyan-400" 
            bg="bg-cyan-500/15" 
            hoverBg="group-hover:bg-cyan-500/25"
            title="Domain Intelligence"
            description="WHOIS registration data, MX records, SPF and DMARC email security analysis."
          />
          <FeatureCard 
            icon={<AlertTriangle className="w-5 h-5" />} 
            color="text-amber-400" 
            bg="bg-amber-500/15" 
            hoverBg="group-hover:bg-amber-500/25"
            title="Risk Scoring"
            description="Automated 0–100 exposure score with breakdown by breach, accounts, and profile."
          />
        </div>
      </section>
    </main>
  );
}

function FeatureCard({ icon, color, bg, hoverBg, title, description }: { icon: React.ReactNode, color: string, bg: string, hoverBg: string, title: string, description: string }) {
  return (
    <div className="rounded-2xl border border-white/5 bg-white/5 p-5 group backdrop-blur-xl transition-all hover:bg-white/10 hover:border-white/10">
      <div className={`w-10 h-10 rounded-xl ${bg} flex items-center justify-center mb-4 ${color} ${hoverBg} transition-colors`}>
        {icon}
      </div>
      <h3 className="font-semibold text-slate-200 mb-1">{title}</h3>
      <p className="text-slate-500 text-sm">{description}</p>
    </div>
  );
}
