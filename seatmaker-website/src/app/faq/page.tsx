import { Metadata } from "next";
import FAQClient from "./faq-client";

export const metadata: Metadata = {
  title: "FAQ",
  description: "Answers about getting started, tables & guests, sharing/export, privacy/offline, payments.",
};

export default function FAQPage() {
  const faqJsonLd = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: [
      {
        "@type": "Question",
        name: "Is Seat Maker free?",
        acceptedAnswer: { "@type": "Answer", text: "Yes, Seat Maker is free to download and use." },
      },
      {
        "@type": "Question",
        name: "Does it work offline?",
        acceptedAnswer: { "@type": "Answer", text: "Yes. Your data stays on device or iCloud if enabled." },
      },
    ],
  };

  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }} />
      <FAQClient />
    </>
  );
}