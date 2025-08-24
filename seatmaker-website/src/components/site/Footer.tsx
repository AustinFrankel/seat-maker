"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

export function Footer() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);
  if (!mounted) return null;
  return (
    <footer className="border-t py-10 text-sm" role="contentinfo">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 grid gap-6 md:grid-cols-4">
        <div className="space-y-2">
          <div className="font-semibold">Seat Maker</div>
          <p className="text-muted-foreground max-w-xs">
            Fast, offline iOS/iPadOS seating charts. Privacy-first. No account
            required.
          </p>
          <div className="flex items-center gap-3 pt-2">
            <Link href="mailto:tablemakercontact@gmail.com" className="hover:underline">
              Contact
            </Link>
            <span aria-hidden>·</span>
            <Link href="https://www.instagram.com/seatmakerapp" target="_blank" rel="noopener noreferrer" className="hover:underline">
              Instagram
            </Link>
          </div>
        </div>
        <nav aria-label="Footer Product">
          <div className="font-medium mb-2">Product</div>
          <ul className="space-y-2 text-muted-foreground">
            <li><a className="hover:underline" href="/#features">Features</a></li>
            <li><a className="hover:underline" href="/#how-it-works">How It Works</a></li>
            <li><Link className="hover:underline" href="/download">Download</Link></li>
          </ul>
        </nav>
        <nav aria-label="Footer Company">
          <div className="font-medium mb-2">Company</div>
          <ul className="space-y-2 text-muted-foreground">
            <li><Link className="hover:underline" href="/about">About</Link></li>
            <li><Link className="hover:underline" href="/about#press">Press</Link></li>
          </ul>
        </nav>
        <nav aria-label="Footer Legal">
          <div className="font-medium mb-2">Legal</div>
          <ul className="space-y-2 text-muted-foreground">
            <li><Link className="hover:underline" href="/privacy">Privacy Policy</Link></li>
          </ul>
        </nav>
      </div>
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row gap-3 sm:items-center sm:justify-between pt-8 text-muted-foreground">
        <div>© {new Date().getFullYear()} Seat Maker · v1.2</div>
        <div className="flex gap-4">
          <Link className="hover:underline" href="mailto:tablemakercontact@gmail.com">
            Contact
          </Link>
          <Link className="hover:underline" href="https://apps.apple.com/us/app/seat-maker/id6748284141" target="_blank" rel="noopener noreferrer">
            App Store
          </Link>
        </div>
      </div>
    </footer>
  );
}


