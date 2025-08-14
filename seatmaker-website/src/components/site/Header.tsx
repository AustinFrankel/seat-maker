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
  { href: "/download", label: "Download" },
  { href: "/key-features", label: "Key Features" },
  { href: "/how-it-works", label: "How It Works" },
  { href: "/faq", label: "FAQ" },
  { href: "/about", label: "About" },
  { href: "/privacy", label: "Privacy Policy" },
];

function Logo() {
  return (
    <div className="transition-transform duration-300 hover:scale-105 active:scale-95">
      <Link href="/download" aria-label="Seat Maker Home" className="font-semibold tracking-tight">
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

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

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
                const active = pathname === item.href;
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
                className="relative transition-transform duration-300 hover:rotate-12"
              >
                <div className="transition-all duration-300">
                  <Sun className="size-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
                  <Moon className="size-5 absolute rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
                </div>
                <span className="sr-only">Toggle theme</span>
              </Button>
            </div>
            <div
              className="transition-all duration-500"
              style={{ animationDelay: "500ms" }}
            >
              <Sheet>
                <SheetTrigger asChild>
                  <Button variant="ghost" size="icon" className="md:hidden" aria-label="Open menu">
                    <Menu className="size-5" />
                  </Button>
                </SheetTrigger>
                <SheetContent side="right" className="w-80" aria-label="Mobile navigation">
                  <div className="flex flex-col gap-2 mt-8">
                    {navItems.map((item, index) => {
                      const active = pathname === item.href;
                      return (
                        <div
                          key={item.href}
                          className="transition-all duration-300"
                          style={{ animationDelay: `${index * 100}ms` }}
                        >
                          <Link
                            href={item.href}
                            className={`block rounded-md px-3 py-2 text-sm transition-colors ${
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
                  </div>
                </SheetContent>
              </Sheet>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}


