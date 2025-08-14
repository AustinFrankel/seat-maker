import { AppStoreBadge } from "@/components/site/AppStoreBadge";
import { DeviceMockups } from "@/components/site/DeviceMockups";
import { FeatureTile } from "@/components/marketing/FeatureTile";
import { TestimonialCard } from "@/components/marketing/TestimonialCard";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";
import Image from "next/image";
import { DemoLink } from "@/components/site/DemoLink";

export default function Home() {
  return (
    <div className="">
      <section className="pt-10 md:pt-16">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 grid md:grid-cols-2 gap-10 items-center">
          <div>
            <div className="inline-flex items-center gap-2 rounded-full bg-secondary px-3 py-1 text-xs">
              <Badge variant="secondary">New</Badge>
              Seat Maker v1.0 — Offline, no login
            </div>
            <h1 className="text-3xl md:text-5xl font-semibold tracking-tight mt-4">
              Plan perfect seating in minutes
            </h1>
            <p className="text-muted-foreground mt-4 max-w-prose">
              Seat Maker lets you design table layouts and assign seats fast. Works fully offline, no account required. Drag & drop guests, lock VIPs, shuffle layouts, and share via QR.
            </p>
            <div className="flex items-center gap-4 mt-6">
              <AppStoreBadge />
              <DemoLink />
            </div>
            <div className="mt-6 flex items-center gap-4 text-xs text-muted-foreground">
              <span>★ ★ ★ ★ ★</span>
              <span>Trusted by event planners</span>
            </div>
          </div>
          <DeviceMockups />
        </div>
      </section>

      <section className="py-12 md:py-16">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid sm:grid-cols-2 md:grid-cols-3 gap-4">
            <FeatureTile title="Why it’s fast" description="Offline-ready, no login, instant drag-and-drop seating." />
            <FeatureTile title="Contact import" description="Quickly bring in guests from Contacts to speed up setup." />
            <FeatureTile title="Shuffle & lock" description="Randomize seating then lock VIPs in place." />
            <FeatureTile title="QR sharing" description="Share plans via QR so others can view instantly." />
            <FeatureTile title="Share easily" description="Share links or images with venues and guests." />
            <FeatureTile title="Works offline" description="No connectivity required. Your data stays on device." />
          </div>
          <Separator className="my-10" />
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4">
            {[1,2,3,4,5].map((n) => (
              <div key={n} className="relative aspect-[9/16] rounded-xl overflow-hidden border">
                <Image
                  src={`/images/seat${n}.png`}
                  alt={`Seat Maker showcase ${n}`}
                  fill
                  sizes="(max-width: 768px) 50vw, 20vw"
                  className="object-contain bg-background"
                />
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-12 md:py-16 bg-secondary/40" id="demo">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 grid md:grid-cols-4 gap-4">
          <TestimonialCard quote="Made my wedding layout in under 10 minutes!" author="Emily, Bride" />
          <TestimonialCard quote="The offline mode is a lifesaver on-site." author="Alex, Event Planner" />
          <TestimonialCard quote="The QR sharing is so slick." author="Taylor, Venue Manager" />
          <TestimonialCard quote="Clean, intuitive, and fast." author="Jordan, Coordinator" />
        </div>
      </section>

      <section className="py-12 md:py-16">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 grid md:grid-cols-2 gap-10 items-start">
          <div>
            <h2 className="text-2xl font-semibold tracking-tight">Custom Tables</h2>
            <p className="text-muted-foreground mt-2">Design custom tables, square, circular, or rectangular, then randomize seating or move guests manually for the perfect arrangement.</p>
            <h2 className="text-2xl font-semibold tracking-tight mt-6">Build Profiles</h2>
            <p className="text-muted-foreground mt-2">Create guest profiles with names, comments, and photos to organize your event’s party seating list effectively.</p>
            <h2 className="text-2xl font-semibold tracking-tight mt-6">Export and Share</h2>
            <p className="text-muted-foreground mt-2">Share your seating plan instantly via message or QR code so friends, family, or your venue can view it immediately.</p>
            <h2 className="text-2xl font-semibold tracking-tight mt-6">View History</h2>
            <p className="text-muted-foreground mt-2">Access past seating layouts to reuse or update previous table setups for your events and parties.</p>
            <h2 className="text-2xl font-semibold tracking-tight mt-6">Personalize and Settings</h2>
            <p className="text-muted-foreground mt-2">Adjust appearance, table settings, view event statistics, and manage profiles and other preferences to tailor your seating experience.</p>
          </div>
          <div className="relative aspect-video rounded-xl overflow-hidden border">
            <Image src="/images/seat3.png" alt="Seat Maker app screenshot" fill className="object-contain bg-background" />
          </div>
        </div>
      </section>

    </div>
  );
}
