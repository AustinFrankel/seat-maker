import { Metadata } from "next";

export const metadata: Metadata = {
  title: "About",
  description: "Short story, mission, privacy-by-design stance, and a light timeline.",
};

export default function AboutPage() {
  return (
    <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 py-10 md:py-16">
      <h1 className="text-3xl font-semibold tracking-tight">About Seat Maker</h1>
      <p className="text-muted-foreground mt-3">
        Seat Maker was built to make event planning faster and calmer. We believe privacy-by-design matters, so the app
        works offline and doesn’t require an account.
      </p>
      <div className="mt-8 space-y-4 text-sm text-muted-foreground">
        <p>
          Our mission is to provide a simple, modern tool for planners and hosts. We care about speed, clarity, and trust.
          That’s why Seat Maker focuses on the essentials and gets out of your way.
        </p>
        <ul className="list-disc pl-5">
          <li>2025 — Initial release on the App Store</li>
        </ul>
      </div>
    </div>
  );
}


