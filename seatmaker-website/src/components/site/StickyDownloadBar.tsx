"use client";

import { useEffect, useState } from "react";
import { AppStoreBadge } from "@/components/site/AppStoreBadge";
import { usePathname } from "next/navigation";

export function StickyDownloadBar() {
  const [visible, setVisible] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    const onScroll = () => {
      const scrolled = window.scrollY;
      const height = document.documentElement.scrollHeight - window.innerHeight;
      setVisible(scrolled / Math.max(height, 1) > 0.25);
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  if (pathname === "/download") return null;

  return null;
}


