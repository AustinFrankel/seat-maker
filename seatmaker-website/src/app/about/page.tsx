import { Metadata } from "next";

export const metadata: Metadata = {
  title: "About",
  description: "Seat Maker’s story, principles, and craft.",
};

export default function AboutPage() {
  return (
    <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 py-10 md:py-16">
      <h1 className="text-3xl font-semibold tracking-tight">About Seat Maker</h1>
      <div className="mt-6 grid gap-10">
        <section>
          <h2 className="text-xl font-medium">Why we built it</h2>
          <p className="text-sm text-muted-foreground mt-2">
            Seating is one of the most stressful parts of hosting. We wanted a tool that felt fast, private, and delightful—so we built one. Seat Maker helps you think through your layout, try options quickly, and communicate clearly with venues and helpers.
          </p>
        </section>
        <section>
          <h2 className="text-xl font-medium">Principles</h2>
          <ul className="list-disc pl-5 text-sm text-muted-foreground mt-2 space-y-1">
            <li><strong>Speed:</strong> Interactions should feel instant. Drag, drop, and shuffle without friction.</li>
            <li><strong>Clarity:</strong> The UI gets out of your way. Your event takes center stage.</li>
            <li><strong>Privacy:</strong> Works offline. No accounts. Your data stays yours.</li>
          </ul>
        </section>
        <section>
          <h2 className="text-xl font-medium">Craft</h2>
          <p className="text-sm text-muted-foreground mt-2">
            We sweat the details—from physics on drag to legible labels at a distance. Accessibility is built-in: Dynamic Type, VoiceOver, and high-contrast themes are supported.
          </p>
        </section>
        <section>
          <h2 className="text-xl font-medium">Roadmap highlights</h2>
          <ul className="list-disc pl-5 text-sm text-muted-foreground mt-2 space-y-1">
            <li>Rules for keeping families together or apart</li>
            <li>Table manager to see and edit all tables at once</li>
            <li>Theme options and custom export templates</li>
          </ul>
        </section>
        <section id="press">
          <h2 className="text-xl font-medium">Team & Press</h2>
          <p className="text-sm text-muted-foreground mt-2">Founder: Austin Frankel. Press contact: <a className="underline" href="mailto:tablemakercontact@gmail.com">tablemakercontact@gmail.com</a></p>
        </section>
      </div>
    </div>
  );
}


