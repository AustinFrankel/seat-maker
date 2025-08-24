import { Metadata } from "next";

export const metadata: Metadata = {
  title: "About",
  description: "Short story, mission, privacy-by-design stance, and a light timeline.",
};

export default function AboutPage() {
  return (
    <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 py-10 md:py-16">
      <h1 className="text-3xl font-semibold tracking-tight">About Seat Maker</h1>
      <div className="mt-6 grid gap-6">
        <section>
          <h2 className="text-xl font-medium">Mission</h2>
          <p className="text-sm text-muted-foreground mt-2">Make event planning faster and calmer with a private-by-design seating chart app.</p>
        </section>
        <section>
          <h2 className="text-xl font-medium">Why privacy</h2>
          <p className="text-sm text-muted-foreground mt-2">Seat Maker works fully offline. No accounts, no tracking—your data stays on your device or iCloud if enabled.</p>
        </section>
        <section>
          <h2 className="text-xl font-medium">Timeline</h2>
          <ul className="list-disc pl-5 text-sm text-muted-foreground mt-2">
            <li>2025 — Initial release</li>
            <li>2025 — v1.2: Shuffle & QR share</li>
          </ul>
        </section>
        <section id="press">
          <h2 className="text-xl font-medium">Team & Press</h2>
          <p className="text-sm text-muted-foreground mt-2">Founder: Austin Frankel. Press contact: <a className="underline" href="mailto:tablemakercontact@gmail.com">tablemakercontact@gmail.com</a></p>
        </section>
        <section>
          <h2 className="text-xl font-medium">Roadmap highlights</h2>
          <ul className="list-disc pl-5 text-sm text-muted-foreground mt-2">
            <li>Themes and color customization</li>
            <li>Seating rules refinements</li>
            <li>Additional export formats</li>
          </ul>
        </section>
      </div>
    </div>
  );
}


