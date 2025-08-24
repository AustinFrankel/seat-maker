"use client";

import { useMemo, useState } from "react";
import { FAQAccordion } from "@/components/marketing/FAQAccordion";
import { Input } from "@/components/ui/input";

export default function FAQClient() {
  const [query, setQuery] = useState("");
  const items = [
    { id: "pricing", question: "How much does Seat Maker cost?", answer: "Seat Maker is free. No ads, no subscriptions." },
    { id: "privacy", question: "How is my data handled?", answer: "No account required. Your data stays on device or iCloud if enabled. We don't track you." },
    { id: "offline", question: "Does it work offline?", answer: "Yes. Everything works without internet. Perfect for venues." },
    { id: "import", question: "Can I import a guest list?", answer: "Yes. Import from Contacts or CSV to build your list fast." },
    { id: "shuffle", question: "How does shuffle work?", answer: "Seat Maker can randomize seating. Lock VIPs to keep them fixed while exploring options." },
    { id: "share", question: "How do I share or export?", answer: "Share via QR for instant viewing or export an image for your venue." },
    { id: "devices", question: "What devices are supported?", answer: "iPhone and iPad on iOS/iPadOS 16 or later. Light and dark mode supported." },
    { id: "support", question: "How do I get support?", answer: "Email tablemakercontact@gmail.com. Include device model and iOS version if reporting an issue." },
  ];

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return items;
    return items.filter((i) => i.question.toLowerCase().includes(q) || i.answer.toLowerCase().includes(q));
  }, [query, items]);

  return (
    <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 py-10 md:py-16">
      <h1 className="text-3xl font-semibold tracking-tight">FAQ</h1>
      <div className="mt-4 max-w-sm">
        <Input
          placeholder="Search questions"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          aria-label="Search FAQs"
        />
      </div>
      <div className="mt-6">
        <FAQAccordion items={filtered} />
      </div>
    </div>
  );
}
