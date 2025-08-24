"use client";

import { useEffect, useRef, useState } from "react";

type Chip = { id: string; x: number; y: number; label: string };

export default function MiniDemo() {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const [chips, setChips] = useState<Chip[]>(() =>
    Array.from({ length: 6 }).map((_, i) => ({ id: String(i), x: 40 + i * 28, y: 260, label: `Guest ${i + 1}` }))
  );
  const [dragId, setDragId] = useState<string | null>(null);
  const [offset, setOffset] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const onMove = (e: MouseEvent | TouchEvent) => {
      if (!dragId || !containerRef.current) return;
      const rect = containerRef.current.getBoundingClientRect();
      const point = 'touches' in e ? e.touches[0] : (e as MouseEvent);
      const nx = (point.clientX - rect.left) - offset.x;
      const ny = (point.clientY - rect.top) - offset.y;
      setChips((prev) => prev.map((c) => (c.id === dragId ? { ...c, x: nx, y: ny } : c)));
    };
    const onUp = () => setDragId(null);
    window.addEventListener('mousemove', onMove, { passive: false });
    window.addEventListener('touchmove', onMove, { passive: false });
    window.addEventListener('mouseup', onUp);
    window.addEventListener('touchend', onUp);
    return () => {
      window.removeEventListener('mousemove', onMove as EventListener);
      window.removeEventListener('touchmove', onMove as EventListener);
      window.removeEventListener('mouseup', onUp);
      window.removeEventListener('touchend', onUp);
    };
  }, [dragId, offset]);

  function onDown(id: string, e: React.MouseEvent | React.TouchEvent) {
    if (!containerRef.current) return;
    const rect = containerRef.current.getBoundingClientRect();
    const point = 'touches' in e ? e.touches[0] : (e as React.MouseEvent);
    const chip = chips.find((c) => c.id === id)!;
    setOffset({ x: (point.clientX - rect.left) - chip.x, y: (point.clientY - rect.top) - chip.y });
    setDragId(id);
  }

  return (
    <div id="mini-demo" className="mt-12">
      <div className="mx-auto max-w-xl rounded-2xl border bg-background p-4 shadow-sm">
        <div ref={containerRef} className="relative h-[360px] overflow-hidden rounded-xl bg-gradient-to-b from-blue-50 to-white dark:from-gray-800 dark:to-gray-900">
          {/* simple round table */}
          <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 h-40 w-40 rounded-full border-2 border-blue-400/60 bg-white/70 backdrop-blur" />
          {chips.map((c) => (
            <button
              key={c.id}
              style={{ transform: `translate(${c.x}px, ${c.y}px)` }}
              className="absolute select-none rounded-full bg-blue-600 px-3 py-1 text-xs font-medium text-white shadow hover:shadow-md active:scale-95"
              onMouseDown={(e) => onDown(c.id, e)}
              onTouchStart={(e) => onDown(c.id, e)}
            >
              {c.label}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}


