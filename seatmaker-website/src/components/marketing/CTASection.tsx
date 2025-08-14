import { AppStoreBadge } from "@/components/site/AppStoreBadge";
import QRCode from "react-qr-code";

export function CTASection() {
  const appStoreUrl = process.env.NEXT_PUBLIC_APP_STORE_URL || "https://apps.apple.com/us/app/seat-maker/id6748284141";
  return (
    <section className="border-t bg-secondary/40">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-14 md:py-20 grid md:grid-cols-2 gap-8 items-center">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight">Ready to make seating simple?</h2>
          <p className="text-muted-foreground mt-2 max-w-prose">
            Download Seat Maker and build beautiful seating charts in minutes. No
            login. Works offline. Share via QR or PDF.
          </p>
          <div className="flex items-center gap-4 mt-5">
            <AppStoreBadge />
          </div>
        </div>
        <div className="flex items-center justify-center">
          <div className="rounded-xl bg-white p-4 shadow-sm border">
            <QRCode value={appStoreUrl} size={132} aria-label="QR code to download Seat Maker" />
          </div>
        </div>
      </div>
    </section>
  );
}


