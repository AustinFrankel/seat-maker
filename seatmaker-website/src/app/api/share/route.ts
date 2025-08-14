import { NextRequest, NextResponse } from "next/server";
import zlib from "node:zlib";
import { put } from "../_store";

function randomSlug(len = 4) {
  const dict = "abcdefghijklmnopqrstuvwxyz0123456789";
  let out = "";
  for (let i = 0; i < len; i++) out += dict[Math.floor(Math.random() * dict.length)];
  return out;
}

type MutableSnapshot = { v: number; seats?: Array<{ n?: string }> };

export async function POST(req: NextRequest) {
  try {
    const doc: unknown = await req.json();
    // minimal validation
    if (typeof doc !== "object" || doc === null || typeof (doc as MutableSnapshot).v !== "number") {
      return NextResponse.json({ error: "invalid" }, { status: 400 });
    }
    // basic PII minimization enforcement: ensure seats names are short
    const obj = doc as MutableSnapshot;
    if (Array.isArray(obj.seats)) {
      obj.seats = obj.seats.map((s) => ({
        ...s,
        n: typeof s.n === "string" ? s.n.slice(0, 24) : "Guest",
      }));
    }
    const slug = randomSlug(4);
    put(slug, obj);

    // Primary viewer URL uses fragment payload so it works without server state
    // Deflate the JSON and encode as base64url to keep it compact
    const json = Buffer.from(JSON.stringify(obj));
    const deflated = zlib.deflateSync(json);
    const b64url = deflated
      .toString("base64")
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/g, "");
    const viewerUrl = `https://www.seatmakerapp.com/t#v=1&d=${b64url}`;

    // Also include slug (may be used in future when persistent storage is available)
    return NextResponse.json({ slug, viewerUrl });
  } catch {
    return NextResponse.json({ error: "bad request" }, { status: 400 });
  }
}


