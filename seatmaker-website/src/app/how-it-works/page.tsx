import { Metadata } from "next";
import { Separator } from "@/components/ui/separator";

export const metadata: Metadata = {
  title: "How It Works",
  description: "Step-by-step tutorial for creating tables, adding guests, dragging to seats, locking, shuffling, and sharing/exporting.",
};

export default function HowItWorksPage() {
  const steps = [
    {
      title: "Create tables",
      body:
        "Start by adding square, circular, or rectangular tables. Resize and label them to match your venue.",
    },
    {
      title: "Add guests",
      body: "Import from Contacts or add names manually. Group families, add notes and photos.",
    },
    {
      title: "Drag to seats",
      body: "Drag guests into chairs. Shuffle to randomize or manually refine seating.",
    },
    { title: "Lock & shuffle", body: "Lock VIP seats, shuffle the rest to explore options quickly." },
    {
      title: "Share",
      body: "Share as a QR for instant viewing or export an image for venues.",
    },
  ];

  return (
    <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-10 md:py-16">
      <h1 className="text-3xl font-semibold tracking-tight">How it works</h1>
      <p className="text-muted-foreground mt-3 max-w-prose">
        A quick walkthrough of Seat Maker. Each step is simple and takes seconds.
      </p>
      <div className="grid md:grid-cols-2 gap-6 mt-8">
        {steps.map((s, i) => (
          <div key={i} className="rounded-xl border p-5">
            <div className="text-xs text-muted-foreground">Step {i + 1}</div>
            <h2 className="text-xl font-medium mt-1">{s.title}</h2>
            <p className="text-sm text-muted-foreground mt-2">{s.body}</p>
          </div>
        ))}
      </div>
      <Separator className="my-10" />
      <div className="text-sm">
        Troubleshooting? See the <a href="/faq" className="underline">FAQ</a>.
      </div>
    </div>
  );
}


