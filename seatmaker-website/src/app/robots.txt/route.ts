import { NextResponse } from "next/server";

export function GET() {
  const base = process.env.NEXT_PUBLIC_SITE_URL || "https://seatmaker.app";
  const body = `User-agent: *
Allow: /
Sitemap: ${base.replace(/\/$/, "")}/sitemap.xml`;
  return new NextResponse(body, { headers: { "Content-Type": "text/plain" } });
}


