import { NextRequest, NextResponse } from "next/server";
import crypto from "node:crypto";
import { put } from "../_store";

function randomSlug(len = 4) {
  const dict = "abcdefghijklmnopqrstuvwxyz0123456789";
  let out = "";
  for (let i = 0; i < len; i++) out += dict[Math.floor(Math.random() * dict.length)];
  return out;
}

export async function POST(req: NextRequest) {
  try {
    const doc = await req.json();
    // minimal validation
    if (typeof doc !== "object" || doc === null || typeof doc.v !== "number") {
      return NextResponse.json({ error: "invalid" }, { status: 400 });
    }
    // basic PII minimization enforcement: ensure seats names are short
    if (Array.isArray(doc.seats)) {
      doc.seats = doc.seats.map((s: any) => ({
        ...s,
        n: typeof s.n === "string" ? s.n.slice(0, 24) : "Guest",
      }));
    }
    let slug = randomSlug(4);
    put(slug, doc);
    const viewerUrl = `https://seatmakerapp.com/t/${slug}`;
    return NextResponse.json({ slug, viewerUrl });
  } catch (e) {
    return NextResponse.json({ error: "bad request" }, { status: 400 });
  }
}


