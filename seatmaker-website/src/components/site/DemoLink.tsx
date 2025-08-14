"use client";

import { useEffect, useState } from "react";

export function DemoLink() {
  const [url, setUrl] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    const candidates = [
      "/images/seatvid.mp4",
      "/images/seatvid.mov",
      "/images/seatvid.webm",
      "/seatvid.mp4",
      "/seatvid.mov",
      "/seatvid.webm",
    ];
    (async () => {
      for (const candidate of candidates) {
        try {
          const res = await fetch(candidate, { method: "HEAD" });
          if (res.ok) {
            if (mounted) setUrl(candidate);
            break;
          }
        } catch {
          // ignore and try next
        }
      }
    })();
    return () => {
      mounted = false;
    };
  }, []);

  if (!url) return null;

  return (
    <a
      href={url}
      className="text-sm hover:underline transition hover:opacity-90"
      target="_blank"
      rel="noopener noreferrer"
    >
      Watch 45-sec demo
    </a>
  );
}


