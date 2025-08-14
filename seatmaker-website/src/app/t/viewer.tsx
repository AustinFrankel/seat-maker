"use client";
import React, { useEffect, useRef, useState } from "react";

type Seat = { tid: string; sid: string; x: number; y: number; n?: string };
type Table = { id: string; kind: "round" | "rect"; cx?: number; cy?: number; r?: number; x?: number; y?: number; w?: number; h?: number; rot?: number; label?: string };
type Snapshot = {
  v: number;
  event?: { title?: string };
  canvas: { w: number; h: number; bg?: string };
  tables: Table[];
  seats: Seat[];
  style?: { seatFill?: string; font?: string };
};

function decodeBase64Url(input: string): Uint8Array {
  input = input.replace(/-/g, "+").replace(/_/g, "/");
  const pad = input.length % 4;
  if (pad) input += "=".repeat(4 - pad);
  const bin = atob(input);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

async function inflate(data: Uint8Array): Promise<Uint8Array> {
  // Use built-in DecompressionStream if available, else fallback to pako (loaded lazily)
  const g = globalThis as unknown as { DecompressionStream?: new (format: string) => TransformStream };
  if (typeof g.DecompressionStream !== "undefined") {
    const ds = new g.DecompressionStream!("deflate");
    const stream = new Response(new ReadableStream({
      start(controller) {
        controller.enqueue(data.buffer);
        controller.close();
      },
    }).pipeThrough(ds));
    const buf = await stream.arrayBuffer();
    return new Uint8Array(buf);
  }
  const { inflate } = await import("pako");
  return inflate(data);
}

async function loadSnapshot(slug?: string): Promise<Snapshot | null> {
  if (typeof window === "undefined") return null;
  // Fragment mode — supports both seatmakerapp.com and www.seatmakerapp.com
  const hash = window.location.hash; // #v=1&d=...
  if (hash && hash.includes("d=")) {
    const params = new URLSearchParams(hash.slice(1));
    const d = params.get("d");
    if (d) {
      const bytes = decodeBase64Url(d);
      const decompressed = await inflate(bytes);
      const text = new TextDecoder().decode(decompressed);
      return JSON.parse(text);
    }
  }
  // Serverless
  if (slug) {
    const res = await fetch(`/api/tables/${slug}`, { cache: "no-store" });
    if (res.status === 410) throw new Error("revoked");
    if (!res.ok) throw new Error("notfound");
    return (await res.json()) as Snapshot;
  }
  return null;
}

function SVGRenderer({ doc }: { doc: Snapshot }) {
  const { w, h, bg } = doc.canvas;
  return (
    <div className="viewer-wrap">
      <svg
        width={Math.min(w, 1000)}
        height={(Math.min(w, 1000) / w) * h}
        viewBox={`0 0 ${w} ${h}`}
        style={{ background: bg || "#fff", borderRadius: 16, boxShadow: "0 10px 30px rgba(0,0,0,0.1)" }}
      >
        {doc.tables.map((t) => {
          if (t.kind === "round") {
            return <circle key={t.id} cx={t.cx} cy={t.cy} r={t.r} fill="#fff" stroke="#222" strokeWidth={6} />;
          }
          const x = t.x ?? 0;
          const y = t.y ?? 0;
          const w = t.w ?? 0;
          const h = t.h ?? 0;
          return (
            <g key={t.id} transform={`rotate(${t.rot || 0}, ${x + w / 2}, ${y + h / 2})`}>
              <rect x={x} y={y} width={w} height={h} rx={28} ry={28} fill="#fff" stroke="#222" strokeWidth={6} />
            </g>
          );
        })}
        {doc.seats.map((s) => (
          <g key={`${s.tid}-${s.sid}`}>
            <circle cx={s.x} cy={s.y} r={32} fill={doc.style?.seatFill || "#eee"} stroke="#fff" strokeWidth={4} />
          </g>
        ))}
        {doc.tables.map((t) => {
          const label = t.label || "";
          const x = t.kind === "round" ? t.cx : (t.x ?? 0) + (t.w ?? 0) / 2;
          const y = t.kind === "round" ? t.cy : (t.y ?? 0) + (t.h ?? 0) / 2;
          return (
            <text key={`${t.id}-label`} x={x} y={y} textAnchor="middle" fontSize={48} fontFamily={doc.style?.font || "-apple-system"} fill="#000">
              {label}
            </text>
          );
        })}
      </svg>
      <style jsx>{`
        .viewer-wrap{display:flex;flex-direction:column;align-items:center;gap:16px}
      `}</style>
    </div>
  );
}

export default function Viewer({ slug }: { slug?: string }) {
  const [doc, setDoc] = useState<Snapshot | null>(null);
  const [error, setError] = useState<string | null>(null);
  const svgRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    document.title = "Seat Maker Viewer";
    const meta = document.createElement("meta");
    meta.name = "robots";
    meta.content = "noindex,nofollow";
    document.head.appendChild(meta);
    (async () => {
      try {
        const snap = await loadSnapshot(slug);
        if (!snap) return setError("notfound");
        setDoc(snap);
      } catch (e) {
        const msg = e instanceof Error ? e.message : "error";
        setError(msg);
      }
    })();
  }, [slug]);

  const downloadPNG = async () => {
    const node = svgRef.current?.querySelector("svg");
    if (!node) return;
    const xml = new XMLSerializer().serializeToString(node);
    const svg64 = btoa(unescape(encodeURIComponent(xml)));
    const image64 = `data:image/svg+xml;base64,${svg64}`;
    const img = new Image();
    img.onload = () => {
      const canvas = document.createElement("canvas");
      canvas.width = img.width;
      canvas.height = img.height;
      const ctx = canvas.getContext("2d")!;
      ctx.drawImage(img, 0, 0);
      const url = canvas.toDataURL("image/png");
      const a = document.createElement("a");
      a.href = url;
      a.download = "seatmaker.png";
      a.click();
    };
    img.src = image64;
  };

  const openInApp = () => {
    if (!doc) return;
    // Trigger Universal Link: prefer current URL (slug or fragment)
    window.location.assign(window.location.href);
  };

  return (
    <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", padding: 24 }}>
      <div style={{ maxWidth: 1100, width: "100%", background: "#fff", borderRadius: 20, boxShadow: "0 20px 60px rgba(0,0,0,0.12)", padding: 24 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
          <div>
            <div style={{ fontSize: 14, color: "#6b7280", fontWeight: 600, letterSpacing: 0.6 }}>Seat Maker</div>
            <div style={{ fontSize: 20, fontWeight: 700 }}>{doc?.event?.title || "Shared layout"}</div>
          </div>
          <div style={{ display: "flex", gap: 8 }}>
            <button onClick={downloadPNG} style={{ padding: "10px 14px", borderRadius: 10, border: "1px solid #e5e7eb", background: "#111827", color: "#fff" }}>Download PNG</button>
            <button onClick={openInApp} style={{ padding: "10px 14px", borderRadius: 10, border: "1px solid #e5e7eb", background: "#fff", color: "#111827" }}>Open in Seat Maker</button>
          </div>
        </div>
        <div ref={svgRef} style={{ display: "flex", justifyContent: "center" }}>
          {error && <div style={{ color: "#ef4444", padding: 24 }}>{error === "revoked" ? "Link revoked." : "Not found."}</div>}
          {!error && doc && <SVGRenderer doc={doc} />}
        </div>
      </div>
    </div>
  );
}


