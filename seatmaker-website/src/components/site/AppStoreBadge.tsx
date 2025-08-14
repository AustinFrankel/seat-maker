"use client";

import Link from "next/link";
import { useTheme } from "next-themes";

function AppleIconDark(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false" {...props}>
      <path
        d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"
        fill="currentColor"
      />
    </svg>
  );
}

function AppleIconLight(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false" {...props}>
      <path
        d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"
        fill="currentColor"
      />
    </svg>
  );
}

export function AppStoreBadge({ className = "" }: { className?: string }) {
  const { theme, resolvedTheme } = useTheme();
  const appStoreUrl = process.env.NEXT_PUBLIC_APP_STORE_URL || "https://apps.apple.com/us/app/seat-maker/id6748284141";
  
  // Determine which theme is actually active
  const currentTheme = resolvedTheme || theme || 'light';
  const isDark = currentTheme === 'dark';
  
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
      className={`
        inline-flex items-center rounded-xl px-4 py-3 
        transition-all duration-200 ease-in-out
        hover:scale-[1.02] focus-visible:outline-none 
        focus-visible:ring-2 focus-visible:ring-offset-2
        ${isDark 
          ? 'bg-white text-black hover:bg-gray-100 focus-visible:ring-white' 
          : 'bg-black text-white hover:bg-gray-900 focus-visible:ring-black'
        }
        ${className}
      `}
      aria-label="Download on the App Store"
    >
      {isDark ? (
        <AppleIconDark className="w-6 h-6 mr-3 flex-shrink-0" />
      ) : (
        <AppleIconLight className="w-6 h-6 mr-3 flex-shrink-0" />
      )}
      <div className="flex flex-col items-start">
        <span className="text-xs leading-tight font-medium">Download on the</span>
        <span className="text-sm font-semibold leading-tight">App Store</span>
      </div>
    </Link>
  );
}


