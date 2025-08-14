import { Card } from "@/components/ui/card";
import { motion } from "framer-motion";

export function TestimonialCard({
  quote,
  author,
}: {
  quote: string;
  author: string;
}) {
  return (
    <motion.div
      whileHover={{ 
        scale: 1.03,
        y: -3,
        transition: { type: "spring", stiffness: 300, damping: 20 }
      }}
      whileTap={{ scale: 0.98 }}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: "easeOut" }}
    >
      <Card className="p-5 h-full transition-all duration-200 hover:shadow-lg hover:shadow-secondary/20 border-secondary/20 hover:border-secondary/40">
        <motion.blockquote 
          className="text-sm leading-relaxed"
          whileHover={{ x: 2 }}
          transition={{ type: "spring", stiffness: 400, damping: 10 }}
        >
          "{quote}"
        </motion.blockquote>
        <motion.div 
          className="mt-3 text-xs text-muted-foreground"
          whileHover={{ x: 2 }}
          transition={{ type: "spring", stiffness: 400, damping: 10 }}
        >
          — {author}
        </motion.div>
      </Card>
    </motion.div>
  );
}


