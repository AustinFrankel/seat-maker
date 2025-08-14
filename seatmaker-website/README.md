Seat Maker marketing site — Next.js + TypeScript + Tailwind + shadcn/ui.

## Getting Started

1) Copy `.env.example` to `.env.local` and set:

```
NEXT_PUBLIC_SITE_URL=http://localhost:3000
NEXT_PUBLIC_APP_STORE_URL=https://apps.apple.com/app/idXXXXXXXXXX
NEXT_PUBLIC_ENABLE_TRACKING=false
```

2) Install deps and run the dev server:

```bash
npm install
npm run dev
```

Open http://localhost:3000.

## Tech

- Next.js App Router, React, TypeScript
- Tailwind CSS v4
- shadcn/ui components
- Accessible, dark mode, SEO metadata (Open Graph & JSON-LD)

## Scripts

- `npm run dev` — start dev server
- `npm run build` — production build
- `npm start` — run production server

## Notes

No third‑party tracking is active unless `NEXT_PUBLIC_ENABLE_TRACKING=true`.

## Deploy

Deploy on Vercel or any Node host.
