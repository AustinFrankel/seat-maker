import { Metadata } from "next";
import { AppStoreBadge } from "@/components/site/AppStoreBadge";
import QRCode from "react-qr-code";

export const metadata: Metadata = {
  title: "Download",
  description:
    "Get Seat Maker on the App Store. QR download, email me the link, and device compatibility notes.",
};

export default function DownloadPage() {
  const appStoreUrl = process.env.NEXT_PUBLIC_APP_STORE_URL || "https://apps.apple.com/us/app/seat-maker/id6748284141";
  return (
    <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-10 md:py-16 grid md:grid-cols-2 gap-10 items-center">
      <div>
        <h1 className="text-3xl font-semibold tracking-tight">Download</h1>
        <p className="text-muted-foreground mt-3">
          Ready to simplify your seating arrangements? Get Seat Maker on the App Store today and start creating the
          perfect seating chart for your next event.
        </p>
        <div className="mt-6 flex items-center gap-4">
          <AppStoreBadge />
        </div>
        {/* Email link form removed to streamline the flow */}
        <div className="mt-6 text-sm text-muted-foreground">
          Compatible with iPhone and iPad. Works offline. No account required.
        </div>
      </div>
        <div className="flex items-center justify-center">
          <div className="rounded-xl bg-white p-4 shadow-sm border">
            <QRCode value={appStoreUrl} size={180} aria-label="QR code to download Seat Maker" />
          </div>
        </div>
    </div>
  );
}


