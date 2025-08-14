import type { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  const base = process.env.NEXT_PUBLIC_SITE_URL || "https://www.seatmakerapp.com";
  const pages = ["/", "/how-it-works", "/key-features", "/download", "/faq", "/press", "/about", "/privacy", "/blog"];
  const now = new Date();
  return pages.map((p) => ({ url: new URL(p, base).toString(), lastModified: now, changeFrequency: "weekly", priority: p === "/" ? 1 : 0.6 }));
}


