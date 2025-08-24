import { Metadata } from "next";
import { AppStoreBadge } from "@/components/site/AppStoreBadge";
import Image from "next/image";
import Link from "next/link";
import { useMemo } from "react";
import { DemoLink } from "@/components/site/DemoLink";
import ContactSection from "@/components/site/ContactSection";
import { DesignStrip } from "@/components/site/DesignStrip";
// Use public asset path to avoid bundler issues; ensure file exists under public/images

export const metadata: Metadata = {
  title: "Seat Maker — Drag-and-Drop Seating Chart App for iPhone & iPad",
  description:
    "Plan wedding and event seating in minutes. Drag & drop tables, shuffle guests, lock VIPs, and share as message or image. Works offline, no account required.",
};

export default function HomePage() {
  const features = useMemo(
    () => [
      { iconColor: "text-blue-600", title: "Drag & Drop Seating", desc: "Move guests with simple touch controls.", href: "#how-it-works" },
      { iconColor: "text-blue-600", title: "Custom Table Layouts", desc: "Round, rectangular, or square—resize and label.", href: "#how-it-works" },
      { iconColor: "text-blue-600", title: "Guest List Import", desc: "Add from Contacts or CSV in one step.", href: "#how-it-works" },
      { iconColor: "text-blue-600", title: "Shuffle & Lock VIPs", desc: "Explore options while keeping key seats fixed.", href: "#how-it-works" },
      { iconColor: "text-blue-600", title: "Share as Message & Image", desc: "Send via Messages or save/export an image.", href: "#how-it-works" },
      { iconColor: "text-blue-600", title: "Offline & Private", desc: "Your data stays on device or iCloud if enabled.", href: "#how-it-works" },
    ],
    []
  );

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white dark:from-gray-900 dark:to-gray-950">
      {/* Hero */}
      <section className="relative pt-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
          <div className="grid lg:grid-cols-2 gap-10 items-center">
            <div className="space-y-7">
              <h1 className="text-[44px] leading-[1.05] sm:text-6xl font-extrabold tracking-tight">
                <span className="block">Create Seating</span>
                <span className="block text-blue-600 dark:text-blue-500">for Events</span>
              </h1>
              <p className="text-base sm:text-lg text-muted-foreground max-w-2xl">
                Drag & drop tables, shuffle guests, lock VIPs, and share as message or image. Works offline. No account required.
              </p>
              <div className="flex flex-col sm:flex-row gap-3">
                <AppStoreBadge className="bg-blue-600 text-white hover:bg-blue-700 shadow-lg ring-1 ring-blue-700/40" />
                <Link href="#how-it-works" className="inline-flex items-center justify-center rounded-xl border px-5 py-3 text-blue-600 border-blue-600 hover:bg-blue-50 dark:hover:bg-blue-950/30 transition-colors">
                  Learn More
                </Link>
              </div>
              <div className="flex items-center gap-4 text-sm text-muted-foreground">
                <span aria-label="Rating five stars">★★★★★</span>
                <span>4.9/5 from 250+ ratings</span>
              </div>
            </div>
            <div className="relative">
              <Image
                src="/images/topImageSeatMaker.png"
                alt="Seat Maker app preview"
                width={480}
                height={960}
                className="mx-auto"
                priority
              />
            </div>
          </div>
        </div>
      </section>

      {/* Features grid */}
      <section id="features" className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <h2 className="text-3xl font-semibold tracking-tight text-center mb-14">Features</h2>
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {features.map((f, idx) => (
              <div key={f.title} className="rounded-2xl p-6 shadow-sm border bg-background transition-transform hover:scale-[1.02]">
                <div className="h-10 w-10 rounded-lg bg-blue-100 dark:bg-blue-950 flex items-center justify-center text-blue-600">
                  <span aria-hidden>
                    {idx === 0 && (/* Drag & Drop */
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 12h16"/><path d="M12 4v16"/></svg>
                    )}
                    {idx === 1 && (/* Tables */
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="8" width="18" height="8" rx="2"/></svg>
                    )}
                    {idx === 2 && (/* Import */
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 3v12"/><path d="M7 10l5 5 5-5"/><path d="M5 19h14"/></svg>
                    )}
                    {idx === 3 && (/* Shuffle/Lock */
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 7h3l3 5 3-5h9"/><path d="M3 17h3l3-5 3 5h9"/></svg>
                    )}
                    {idx === 4 && (/* Share as message & image */
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a4 4 0 0 1-4 4H7l-4 3V7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4z"/></svg>
                    )}
                    {idx === 5 && (/* Offline */
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><path d="M2 2l20 20"/></svg>
                    )}
                  </span>
                  <span className="sr-only">{f.title}</span>
                </div>
                <h3 className="text-lg font-medium mt-4">{f.title}</h3>
                <p className="text-sm text-muted-foreground mt-1">{f.desc}</p>
                <a href={f.href} className="mt-3 inline-block text-sm underline underline-offset-4">See how</a>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Gallery carousel placeholder (snap) */}
      <section aria-labelledby="gallery-heading" className="py-20 [perspective:1000px]">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <h2 id="gallery-heading" className="text-3xl font-semibold tracking-tight text-center mb-10">See Seat Maker in Action</h2>
          <div className="overflow-x-auto snap-x snap-mandatory flex gap-6 pb-4" aria-label="App gallery" role="region">
            {[
              {i:1, caption:"Drag guests into any seat"},
              {i:2, caption:"Build custom round, square, or rectangle tables"},
              {i:3, caption:"Shuffle results to explore options"},
              {i:4, caption:"Lock VIPs before shuffling"},
              {i:5, caption:"Share as message or image"},
            ].map(({i, caption}) => (
              <figure key={i} className="min-w-[280px] sm:min-w-[360px] snap-start will-change-transform hover:[transform:rotateX(6deg)_translateY(-2px)] transition-transform">
                <Image src={`/images/seat${i}.png`} alt={`Seat Maker seating chart UI ${i}`} width={360} height={640} className="rounded-xl shadow-lg" />
                <figcaption className="mt-2 text-sm text-muted-foreground">{caption}</figcaption>
              </figure>
            ))}
          </div>
        </div>
      </section>

      {/* How it works */}
      <section id="how-it-works" className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <h2 className="text-3xl font-semibold tracking-tight text-center mb-14">How It Works</h2>
          <div className="grid md:grid-cols-2 gap-6">
            {[
              { step: 1, title: "Create tables", tip: "Resize and label tables to match your venue.", icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="8" width="18" height="8" rx="2"/></svg> },
              { step: 2, title: "Add guests", tip: "Import from Contacts or CSV.", icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M16 11c1.66 0 3-1.34 3-3s-1.34-3-3-3-3 1.34-3 3 1.34 3 3 3z"/><path d="M2 20c0-3.31 2.69-6 6-6h4"/></svg> },
              { step: 3, title: "Drag to seats", tip: "Group families to seat faster.", icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 12h16"/><path d="M12 4v16"/></svg> },
              { step: 4, title: "Lock & shuffle", tip: "Fix VIPs, explore options.", icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg> },
              { step: 5, title: "Share", tip: "Send as a message or export an image.", icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 12v8h16v-8"/><path d="M12 16V4"/><path d="M8 8l4-4 4 4"/></svg> },
            ].map((s) => (
              <div key={s.step} className="rounded-2xl p-6 shadow-sm border bg-background">
                <div className="flex items-center gap-2 text-xs text-muted-foreground"><span className="inline-flex h-6 w-6 items-center justify-center rounded bg-blue-100 text-blue-700">{s.step}</span>{s.icon}</div>
                <h3 className="text-lg font-medium mt-2">{s.title}</h3>
                <p className="text-sm text-muted-foreground mt-2">Tip: {s.tip}</p>
              </div>
            ))}
          </div>
          {/** Live mini demo link removed **/}
        </div>
      </section>

      {/* Design showcase strip */}
      <DesignStrip />

      {/* Reviews */}
      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <h2 className="text-3xl font-semibold tracking-tight text-center mb-8">Loved by planners, teachers, and hosts</h2>
          <div className="text-center text-sm text-muted-foreground mb-8">★★★★★ 4.9/5 · 250+ ratings</div>
          <div className="overflow-x-auto snap-x snap-mandatory flex gap-4 pb-2" aria-label="Customer reviews" role="region">
            {[
              {q:"Made seating painless and actually fun.", a:"Wedding planner"},
              {q:"My class charts are organized in minutes.", a:"Teacher"},
              {q:"Shuffle + lock VIPs saved us hours.", a:"Event host"},
              {q:"Perfect for corporate dinners.", a:"Corporate planner"},
              {q:"Offline mode worked great at the venue.", a:"Venue coordinator"},
              {q:"Sharing via Messages impressed everyone.", a:"Bride"},
              {q:"Best seating app I’ve tried.", a:"Parent"},
              {q:"So fast for galas and fundraisers.", a:"Nonprofit"},
            ].map((r, i) => (
              <blockquote key={i} className="min-w-[260px] sm:min-w-[320px] snap-start rounded-2xl p-5 shadow-sm border bg-background">
                <p className="text-sm leading-relaxed">“{r.q}”</p>
                <footer className="mt-2 text-xs text-muted-foreground">— {r.a}</footer>
              </blockquote>
            ))}
          </div>
          <div className="text-center mt-6 text-sm">
            <Link href="/download" className="underline">More reviews on the App Store</Link>
          </div>
        </div>
      </section>

      {/* Contact */}
      <ContactSection />

      {/* Big CTA band */}
      <section className="py-20 bg-blue-100 dark:bg-blue-950/30">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl font-bold mb-3">Ready to build your seating plan?</h2>
          <p className="text-lg mb-8">Get Seat Maker on the App Store.</p>
          <AppStoreBadge className="bg-blue-600 text-white hover:bg-blue-700 shadow-lg ring-1 ring-blue-700/40" />
        </div>
      </section>

      {/* Live mini demo removed */}
    </div>
  );
}
