"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Search, Loader2 } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";

export default function SearchForm() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;

    setLoading(true);
    try {
      const res = await fetch("/api/v1/search", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      const data = await res.json();
      if (!res.ok || !data.success) {
        throw new Error(data.error || "Failed to start search");
      }
      
      router.push(`/dashboard/${data.search_id}`);
    } catch (error: any) {
      toast.error(error.message);
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSearch} className="flex flex-col sm:flex-row gap-3 w-full max-w-2xl mx-auto z-10 relative">
      <div className="flex-1 relative">
        <div className="absolute left-4 top-1/2 -translate-y-1/2 text-muted-foreground">
          <Search className="w-5 h-5" />
        </div>
        <Input
          type="email"
          name="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="target@example.com"
          className="pl-12 h-12 text-base bg-background/50 border-input shadow-sm"
          required
          autoComplete="off"
          spellCheck="false"
        />
      </div>
      <Button
        type="submit"
        disabled={!email || loading}
        className="h-12 px-8 min-w-36 text-base"
      >
        {loading ? (
          <Loader2 className="w-5 h-5 animate-spin" />
        ) : (
          "Investigate"
        )}
      </Button>
    </form>
  );
}
