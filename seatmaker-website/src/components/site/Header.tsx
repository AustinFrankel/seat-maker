"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { Moon, Sun, Menu } from "lucide-react";
import { useTheme } from "next-themes";
import { AppStoreBadge } from "@/components/site/AppStoreBadge";

const navItems: Array<{ href: string; label: string }> = [
  { href: "/#features", label: "Features" },
  { href: "/#how-it-works", label: "How It Works" },
  { href: "/#contact", label: "Contact" },
  { href: "/faq", label: "FAQ" },
  { href: "/about", label: "About" },
  { href: "/privacy", label: "Privacy" },
];

function Logo() {
  return (
    <div className="transition-transform duration-300 hover:scale-105 active:scale-95">
      <Link href="/" aria-label="Seat Maker Home" className="font-semibold tracking-tight">
        <span className="text-base">Seat</span>
        <span className="text-base"> Maker</span>
      </Link>
    </div>
  );
}

export function Header() {
  const pathname = usePathname();
  const { theme, setTheme } = useTheme();
  const [scrolled, setScrolled] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  useEffect(() => setMounted(true), []);

  return (
    <header
      className={`sticky top-0 z-50 backdrop-blur supports-[backdrop-filter]:bg-background/70 border-b transition-all duration-300 ${
        scrolled ? "shadow-sm" : ""
      }`}
    >
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className={`flex items-center justify-between ${scrolled ? "py-2" : "py-3"}`}>
          <div className="flex items-center gap-4">
            <Logo />
            <nav className="hidden md:flex items-center gap-1" aria-label="Primary">
              {navItems.map((item, index) => {
                const isAnchor = item.href.startsWith("/#");
                // Never mark anchor links active on initial render to avoid double-highlight
                const active = !isAnchor && pathname === item.href;
                return (
                  <div
                    key={item.href}
                    className="transition-all duration-300"
                    style={{ animationDelay: `${index * 100}ms` }}
                  >
                    <Link
                      href={item.href}
                      className={`rounded-md px-3 py-2 text-sm transition-colors ${
                        active
                          ? "bg-secondary text-foreground"
                          : "text-foreground/80 hover:text-foreground hover:bg-secondary"
                      }`}
                      aria-current={active ? "page" : undefined}
                    >
                      {item.label}
                    </Link>
                  </div>
                );
              })}
            </nav>
          </div>
          <div className="flex items-center gap-2">
            <div 
              className="hidden sm:inline-flex transition-all duration-500"
              style={{ animationDelay: "300ms" }}
            >
              <AppStoreBadge />
            </div>
            <div
              className="transition-all duration-500"
              style={{ animationDelay: "400ms" }}
            >
              <Button
                variant="ghost"
                size="icon"
                aria-label="Toggle theme"
                onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
                className="relative transition-transform duration-300 hover:rotate-12 active:translate-y-0"
              >
                {mounted && (
                  <div className="transition-all duration-300 will-change-transform">
                    <Sun className="size-5 rotate-0 scale-100 transition-transform dark:-rotate-90 dark:scale-0" />
                    <Moon className="size-5 absolute rotate-90 scale-0 transition-transform dark:rotate-0 dark:scale-100" />
                  </div>
                )}
                <span className="sr-only">Toggle theme</span>
              </Button>
            </div>
            <div className="transition-all duration-500" style={{ animationDelay: "500ms" }}>
              <Link href="/mobile-menu" className="md:hidden inline-flex rounded-md px-3 py-2 text-sm hover:bg-secondary" aria-label="Open menu">
                <Menu className="size-5" />
              </Link>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}


