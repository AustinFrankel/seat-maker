import Link from "next/link";

export const dynamic = "error";

export default function MobileMenuPage() {
  const items: Array<{ href: string; label: string }> = [
    { href: "/#features", label: "Features" },
    { href: "/#how-it-works", label: "How It Works" },
    { href: "/#contact", label: "Contact" },
    { href: "/faq", label: "FAQ" },
    { href: "/about", label: "About" },
    { href: "/privacy", label: "Privacy" },
    { href: "/download", label: "Download" },
  ];
  return (
    <div className="mx-auto max-w-md px-6 py-10">
      <h1 className="text-2xl font-semibold tracking-tight mb-6">Menu</h1>
      <nav className="grid gap-3" aria-label="Mobile menu">
        {items.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className="block rounded-xl border px-4 py-4 text-base hover:bg-secondary transition-colors"
          >
            {item.label}
          </Link>
        ))}
      </nav>
    </div>
  );
}


