"use client";

import { useMemo, useState } from "react";
import { FAQAccordion } from "@/components/marketing/FAQAccordion";
import { Input } from "@/components/ui/input";

export default function FAQClient() {
  const [query, setQuery] = useState("");
  const items = [
    { id: "what", question: "What is Seat Maker used for?", answer: "Seat Maker is used for seating at events, parties, and more. It is a fun and easy way to create custom seating." },
    { id: "share", question: "How do I share or export my seating chart?", answer: "You have to hit the export button after making your table and click on share as message or QR code." },
    { id: "free", question: "Is Seat Maker free to use?", answer: "Yes. Seat Maker is free to download and use." },
    { id: "offline", question: "Can I use Seat Maker without an internet connection?", answer: "Yes. Table Maker works fully offline. You can create and edit seating charts anytime." },
    { id: "support", question: "How do I get more help or report an issue?", answer: "If you have questions or need support, please contact us at TableMakerContact@gmail.com. We also recommend checking the Help section inside the app for tips and tutorials. We're happy to assist with any technical issues or feedback you have." },
    { id: "import", question: "Can I import contacts?", answer: "Yes, import names from your Contacts to build your guest list faster." },
    { id: "rules", question: "Does it support seating rules?", answer: "You can lock certain seats, keep guests together, and avoid specific pairings to reduce conflicts." },
    { id: "sharing", question: "How do I share?", answer: "Share a QR link or export an image for printing or sending to venues." },
    { id: "qr", question: "How does QR sharing work?", answer: "Generate a QR code so others can view your plan instantly on their devices." },
    { id: "devices", question: "What devices are supported?", answer: "iPhone and iPad running recent iOS/iPadOS versions." },
    { id: "privacy", question: "Do you track my data?", answer: "No. Your data stays on device or in your iCloud if enabled. No tracking or selling of data." },
    { id: "price", question: "How much does it cost?", answer: "Seat Maker is free." },
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
