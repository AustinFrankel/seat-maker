"use client";
import React from "react";
import Viewer from "../../t/viewer";

export default function Page({ params }: { params: Promise<{ slug: string }> }) {
  const [slug, setSlug] = React.useState<string | null>(null);
  React.useEffect(() => {
    (async () => {
      const p = await params;
      setSlug(p.slug);
    })();
  }, [params]);
  return <Viewer slug={slug ?? undefined} />;
}


