import Link from "next/link";

export default function NotFound() {
  return (
    <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 py-16 text-center">
      <h1 className="text-3xl font-semibold tracking-tight">Page not found</h1>
      <p className="text-muted-foreground mt-2">Sorry, we couldn&apos;t find what you&apos;re looking for.</p>
      <Link href="/" className="underline mt-6 inline-block">Return home</Link>
    </div>
  );
}


