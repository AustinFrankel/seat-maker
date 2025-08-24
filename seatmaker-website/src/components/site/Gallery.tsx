"use client";

import Image from "next/image";
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";

export function Gallery() {
  const items = [
    { i: 1, caption: "Drag guests into any seat" },
    { i: 2, caption: "Build custom round, square, or rectangle tables" },
    { i: 3, caption: "Shuffle results to explore options" },
    { i: 4, caption: "Lock VIPs before shuffling" },
    { i: 5, caption: "Share as message or image" },
  ];
  const [active, setActive] = useState<number | null>(null);

  return (
    <div>
      <div className="overflow-x-auto snap-x snap-mandatory flex gap-6 pb-4" aria-label="App gallery" role="region">
        {items.map(({ i, caption }) => (
          <figure
            key={i}
            className="min-w-[280px] sm:min-w-[360px] snap-start will-change-transform hover:[transform:rotateX(6deg)_translateY(-2px)] transition-transform cursor-zoom-in"
            onClick={() => setActive(i)}
          >
            <Image src={`/images/seat${i}.png`} alt={`Seat Maker seating chart UI ${i}`} width={360} height={640} className="rounded-xl shadow-lg" />
            <figcaption className="mt-2 text-sm text-muted-foreground">{caption}</figcaption>
          </figure>
        ))}
      </div>

      <AnimatePresence>
        {active && (
          <motion.div
            className="fixed inset-0 z-[60] bg-black/70 backdrop-blur-sm flex items-center justify-center p-4"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setActive(null)}
          >
            <motion.div
              className="relative max-w-[90vw] max-h-[85vh]"
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
            >
              <Image
                src={`/images/seat${active}.png`}
                alt={`Seat Maker screenshot ${active}`}
                width={800}
                height={1400}
                className="rounded-xl shadow-2xl"
              />
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
