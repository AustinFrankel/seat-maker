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

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "https://www.seatmakerapp.com";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "Seat Maker — Drag-and-Drop Seating Chart App for iPhone & iPad",
    template: "%s · Seat Maker",
  },
  description:
    "Plan wedding and event seating in minutes. Drag & drop tables, shuffle guests, lock VIPs, and share as message or image. Works offline, no account required.",
  keywords: [
    "seating chart app",
    "wedding seating",
    "event planning",
    "drag and drop",
    "table layout",
    "iPhone",
    "iPad",
  ],
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    url: siteUrl,
    title: "Seat Maker — Drag-and-Drop Seating Chart App for iPhone & iPad",
    description:
      "Plan wedding and event seating in minutes. Drag & drop tables, shuffle guests, lock VIPs, and share as message or image. Works offline, no account required.",
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
    title: "Seat Maker — Drag-and-Drop Seating Chart App for iPhone & iPad",
    description:
      "Plan wedding and event seating in minutes. Drag & drop tables, shuffle guests, lock VIPs, and share as message or image. Works offline, no account required.",
    images: ["/og.png"],
  },
  robots: { index: true, follow: true },
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

  const orgJsonLd = {
    "@context": "https://schema.org",
    "@type": "Organization",
    name: "Seat Maker",
    url: siteUrl,
    sameAs: ["https://www.instagram.com/seatmakerapp"],
  };

  const breadcrumbJsonLd = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      { "@type": "ListItem", position: 1, name: "Product", item: `${siteUrl}/` },
      { "@type": "ListItem", position: 2, name: "FAQ", item: `${siteUrl}/faq` },
      { "@type": "ListItem", position: 3, name: "About", item: `${siteUrl}/about` },
      { "@type": "ListItem", position: 4, name: "Privacy", item: `${siteUrl}/privacy` },
      { "@type": "ListItem", position: 5, name: "Download", item: `${siteUrl}/download` },
    ],
  };

  return (
    <html lang="en" suppressHydrationWarning className="scroll-smooth">
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
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(orgJsonLd) }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbJsonLd) }}
        />
      </body>
    </html>
  );
}
