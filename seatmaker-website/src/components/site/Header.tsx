"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { Moon, Sun, Menu } from "lucide-react";
import { useTheme } from "next-themes";
import { AppStoreBadge } from "@/components/site/AppStoreBadge";
import { motion, AnimatePresence } from "framer-motion";

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
    <motion.div
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      transition={{ type: "spring", stiffness: 400, damping: 10 }}
    >
      <Link href="/download" aria-label="Seat Maker Home" className="font-semibold tracking-tight">
        <span className="text-base">Seat</span>
        <span className="text-base"> Maker</span>
      </Link>
    </motion.div>
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

  const appStoreUrl = process.env.NEXT_PUBLIC_APP_STORE_URL || "https://apps.apple.com/us/app/seat-maker/id6748284141";

  return (
    <motion.header
      initial={{ y: -100, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ duration: 0.6, ease: "easeOut" }}
      className={`sticky top-0 z-50 backdrop-blur supports-[backdrop-filter]:bg-background/70 border-b ${
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
                  <motion.div
                    key={item.href}
                    initial={{ opacity: 0, y: -20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.5, delay: index * 0.1 }}
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
                  </motion.div>
                );
              })}
            </nav>
          </div>
          <div className="flex items-center gap-2">
            <motion.div 
              className="hidden sm:inline-flex"
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.5, delay: 0.3 }}
            >
              <AppStoreBadge />
            </motion.div>
            <motion.div
              initial={{ opacity: 0, rotate: -180 }}
              animate={{ opacity: 1, rotate: 0 }}
              transition={{ duration: 0.5, delay: 0.4 }}
            >
              <Button
                variant="ghost"
                size="icon"
                aria-label="Toggle theme"
                onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
                className="relative"
              >
                <motion.div
                  initial={false}
                  animate={theme === "dark" ? { rotate: 180 } : { rotate: 0 }}
                  transition={{ duration: 0.3, ease: "easeInOut" }}
                >
                  <Sun className="size-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
                  <Moon className="size-5 absolute rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
                </motion.div>
                <span className="sr-only">Toggle theme</span>
              </Button>
            </motion.div>
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, delay: 0.5 }}
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
                        <motion.div
                          key={item.href}
                          initial={{ opacity: 0, x: 20 }}
                          animate={{ opacity: 1, x: 0 }}
                          transition={{ duration: 0.3, delay: index * 0.1 }}
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
                        </motion.div>
                      );
                    })}
                  </div>
                </SheetContent>
              </Sheet>
            </motion.div>
          </div>
        </div>
      </div>
    </motion.header>
  );
}


