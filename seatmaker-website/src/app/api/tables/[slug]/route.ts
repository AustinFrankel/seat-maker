import { NextRequest, NextResponse } from "next/server";
import { get, revoke } from "../../_store";

export async function GET(_req: NextRequest, { params }: { params: { slug: string } }) {
  const item = get(params.slug);
  if (!item) return NextResponse.json({ error: "not found" }, { status: 404 });
  if (item.revoked) return NextResponse.json({ error: "revoked" }, { status: 410 });
  return NextResponse.json(item.doc, { headers: { "Cache-Control": "no-store" } });
}

export async function POST(_req: NextRequest, { params }: { params: { slug: string } }) {
  // revoke
  revoke(params.slug);
  return NextResponse.json({ ok: true });
}


