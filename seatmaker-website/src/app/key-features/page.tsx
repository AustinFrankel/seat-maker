import { Metadata } from "next";
import { FeatureTile } from "@/components/marketing/FeatureTile";

export const metadata: Metadata = {
  title: "Key Features",
  description:
    "Easy drag & drop, custom table layouts, guest list management, smart seating rules, share & export, offline & secure.",
};

export default function KeyFeaturesPage() {
  const features = [
    {
      title: "Easy Drag & Drop Interface",
      description:
        "Quickly add tables and seats, then move them around with a simple touch. No design skills needed – just drag tables and guests into place.",
    },
    {
      title: "Custom Table Layouts",
      description:
        "Choose from round, rectangular, or custom table shapes. Resize and label tables to match your venue’s floor plan.",
    },
    {
      title: "Guest List Management",
      description:
        "Import names from Contacts or add them manually. Group families, add notes and photos.",
    },
    {
      title: "Share & Export",
      description:
        "Share via QR or image exports for your venue or guests.",
    },
    {
      title: "Offline & Private",
      description:
        "Works fully offline. No account required. Your data stays on device or iCloud if enabled.",
    },
    {
      title: "Shuffle & Lock VIPs",
      description:
        "Automatically generate new combinations, lock important seats, and fine‑tune by hand.",
    },
    {
      title: "Accessibility & Dark Mode",
      description:
        "Designed for iPhone and iPad with VoiceOver, Dynamic Type, and dark mode supported.",
    },
  ];

  return (
    <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-10 md:py-16">
      <h1 className="text-3xl font-semibold tracking-tight">Key Features</h1>
      <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4 mt-6">
        {features.map((f) => (
          <FeatureTile key={f.title} title={f.title} description={f.description} />
        ))}
      </div>
    </div>
  );
}


