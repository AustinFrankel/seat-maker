import { NextResponse } from "next/server";
import { get, revoke } from "../../_store";

export async function GET(req: Request) {
  const { pathname } = new URL(req.url);
  const slug = pathname.split("/").pop() || "";
  const item = get(slug);
  if (!item) return NextResponse.json({ error: "not found" }, { status: 404 });
  if (item.revoked) return NextResponse.json({ error: "revoked" }, { status: 410 });
  return NextResponse.json(item.doc, { headers: { "Cache-Control": "no-store" } });
}

export async function POST(req: Request) {
  // revoke
  const { pathname } = new URL(req.url);
  const slug = pathname.split("/").pop() || "";
  revoke(slug);
  return NextResponse.json({ ok: true });
}


