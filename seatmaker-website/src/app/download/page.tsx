import { Metadata } from "next";
import { AppStoreBadge } from "@/components/site/AppStoreBadge";
import QRCode from "react-qr-code";

export const metadata: Metadata = {
  title: "Download Seat Maker — Fast, Offline Seating Charts",
  description:
    "Design table layouts and drag guests into seats in seconds. Offline-ready, no login, share via QR. Download now on the App Store.",
};

export default function DownloadPage() {
  const appStoreUrl = process.env.NEXT_PUBLIC_APP_STORE_URL || "https://apps.apple.com/us/app/seat-maker/id6748284141";
  
  return (
    <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-10 md:py-16">
      <div className="text-center">
        <h1 className="text-3xl font-semibold tracking-tight mb-4">Download Seat Maker v1.2</h1>
        <p className="text-muted-foreground mb-6">
          Ready to simplify your seating arrangements? Get Seat Maker on the App Store today.
        </p>
        <div className="flex items-center justify-center gap-6">
          <AppStoreBadge />
          <div className="rounded-xl bg-white p-4 shadow-sm border">
            <QRCode value={appStoreUrl} size={180} aria-label="QR code to download Seat Maker" />
          </div>
        </div>
      </div>
    </div>
  );
}


