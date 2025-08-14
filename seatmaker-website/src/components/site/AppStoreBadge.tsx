"use client";

import Link from "next/link";

function AppleIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false" {...props}>
      <path
        d="M16.365 1.43c0 1.14-.46 2.26-1.272 3.08-.81.82-2.046 1.44-3.143 1.35-.14-1.09.43-2.24 1.23-3.1.83-.9 2.27-1.58 3.2-1.33.01.01-.01 0-.01 0zM21.9 17.23c-.42.97-.92 1.86-1.5 2.66-.79 1.1-1.44 1.86-2.09 2.36-.85.7-1.76 1.07-2.74 1.09-.7.02-1.17-.16-1.61-.33-.36-.14-.74-.29-1.28-.29-.56 0-.95.15-1.33.3-.42.17-.85.35-1.49.34-.98-.02-1.9-.4-2.75-1.1-.58-.48-1.28-1.22-2.1-2.33-.9-1.21-1.64-2.62-2.23-4.23-.63-1.72-.95-3.39-.96-4.99-.01-1.61.35-2.98 1.1-4.13.58-.89 1.35-1.58 2.31-2.08.96-.5 1.99-.76 3.06-.78.76-.01 1.47.18 2.12.43.5.19.92.36 1.25.36.3 0 .71-.16 1.25-.38.74-.29 1.42-.41 2.04-.36 1.5.12 2.64.61 3.41 1.48-1.35.82-2.28 2.11-2.27 3.68.02 1.47.83 2.86 2.09 3.61.62.38 1.31.58 2.06.61-.17.52-.36 1.02-.57 1.5z"
        fill="currentColor"
      />
    </svg>
  );
}

export function AppStoreBadge({ className = "" }: { className?: string }) {
  const appStoreUrl = process.env.NEXT_PUBLIC_APP_STORE_URL || "https://apps.apple.com/us/app/seat-maker/id6748284141";
  function trackClick() {
    if (process.env.NEXT_PUBLIC_ENABLE_TRACKING === "true") {
      // Stub for analytics. Intentionally a no-op unless enabled via env.
      console.log("App Store badge clicked");
    }
  }
  return (
    <Link
      href={appStoreUrl}
      prefetch={false}
      onClick={trackClick}
      className={`inline-flex items-center rounded-xl bg-black text-white px-4 py-2 transition hover:scale-[1.02] hover:bg-black/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-black ${className}`}
      aria-label="Download on the App Store"
    >
      <AppleIcon className="size-6 mr-2" />
      <span className="text-xs leading-none">Download on the</span>
      <span className="ml-1 text-sm font-semibold leading-none">App Store</span>
    </Link>
  );
}


