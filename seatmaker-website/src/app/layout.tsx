import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/components/theme-provider";
import { Header } from "@/components/site/Header";
import { Footer } from "@/components/site/Footer";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "https://seatmakerapp.com";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "Seat Maker v1.2 — Fast, Offline Seating Charts",
    template: "%s · Seat Maker",
  },
  description:
    "Design table layouts and drag guests into seats in seconds. Offline-ready, no login, share via QR. Download now on the App Store.",
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    url: siteUrl,
    title: "Seat Maker v1.2 — Fast, Offline Seating Charts",
    description:
      "Design table layouts and drag guests into seats in seconds. Offline-ready, no login, share via QR. Download now on the App Store.",
    images: [
      {
        url: "/og.png",
        width: 1200,
        height: 630,
        alt: "Seat Maker – iPhone/iPad mockups and features",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Seat Maker v1.2 — Fast, Offline Seating Charts",
    description:
      "Design table layouts and drag guests into seats in seconds. Offline-ready, no login, share via QR. Download now on the App Store.",
    images: ["/og.png"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: "Seat Maker",
    applicationCategory: "BusinessApplication",
    operatingSystem: "iOS, iPadOS",
    softwareVersion: "1.2",
    offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
    aggregateRating: {
      "@type": "AggregateRating",
      ratingValue: "4.9",
      reviewCount: "124",
    },
    url: siteUrl,
  };

  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${geistSans.variable} ${geistMono.variable} antialiased`} suppressHydrationWarning>
        <a href="#main" className="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 z-50 rounded bg-secondary px-3 py-2">
          Skip to content
        </a>
        <ThemeProvider>
          <Header />
          <main id="main" className="min-h-[70vh]">
            {children}
          </main>
          <Footer />
        </ThemeProvider>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </body>
    </html>
  );
}
