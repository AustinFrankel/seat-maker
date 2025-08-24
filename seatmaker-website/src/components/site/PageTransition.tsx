"use client";

import { AnimatePresence, MotionConfig, motion, useReducedMotion } from "framer-motion";
import { usePathname } from "next/navigation";
import React from "react";

export function PageTransition({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const prefersReduced = useReducedMotion();

  const variants = prefersReduced
    ? {
        initial: { opacity: 0 },
        animate: { opacity: 1 },
        exit: { opacity: 0 },
      }
    : {
        initial: { opacity: 0, y: 12 },
        animate: { opacity: 1, y: 0 },
        exit: { opacity: 0, y: -12 },
      };

  return (
    <MotionConfig transition={{ duration: 0.22, ease: "easeOut" }}>
      <AnimatePresence mode="wait" initial={false}>
        <motion.div key={pathname} initial="initial" animate="animate" exit="exit" variants={variants}>
          {children}
        </motion.div>
      </AnimatePresence>
    </MotionConfig>
  );
}


