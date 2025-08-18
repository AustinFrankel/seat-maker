import { NextResponse } from "next/server";

export function GET() {
  const base = process.env.NEXT_PUBLIC_SITE_URL || "https://www.seatmakerapp.com";
  const body = `User-agent: Google-adstxt
Disallow:

User-agent: Mediapartners-Google
Disallow:

User-agent: *
Allow: /
Allow: /app-ads.txt
Sitemap: ${base.replace(/\/$/, "")}/sitemap.xml`;
  return new NextResponse(body, { 
    headers: { 
      "Content-Type": "text/plain; charset=utf-8",
      "Cache-Control": "no-cache, no-store, must-revalidate"
    } 
  });
}


