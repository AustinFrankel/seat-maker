import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  try {
    const { email, link } = await req.json();
    if (!email || typeof email !== "string") {
      return NextResponse.json({ ok: false, error: "Invalid email" }, { status: 400 });
    }
    // Stub: in production, integrate with an email service (e.g., Resend, SES, Postmark)
    return NextResponse.json({ ok: true, message: `Would send ${link || "app link"} to ${email}` });
  } catch {
    return NextResponse.json({ ok: false, error: "Bad request" }, { status: 400 });
  }
}


