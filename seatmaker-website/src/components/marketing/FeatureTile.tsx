import { Card } from "@/components/ui/card";
import { motion } from "framer-motion";

export function FeatureTile({
  title,
  description,
  icon,
}: {
  title: string;
  description: string;
  icon?: React.ReactNode;
}) {
  return (
    <motion.div
      whileHover={{ 
        scale: 1.02,
        y: -2,
        transition: { type: "spring", stiffness: 300, damping: 20 }
      }}
      whileTap={{ scale: 0.98 }}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, ease: "easeOut" }}
    >
      <Card className="p-5 h-full transition-all duration-200 hover:shadow-lg hover:shadow-primary/10 border-primary/20 hover:border-primary/40">
        <div className="flex items-start gap-3">
          {icon ? (
            <motion.div 
              className="mt-0.5 text-primary"
              whileHover={{ rotate: 5, scale: 1.1 }}
              transition={{ type: "spring", stiffness: 400, damping: 10 }}
            >
              {icon}
            </motion.div>
          ) : null}
          <div>
            <motion.h3 
              className="text-sm font-semibold leading-none mb-2"
              whileHover={{ x: 2 }}
              transition={{ type: "spring", stiffness: 400, damping: 10 }}
            >
              {title}
            </motion.h3>
            <p className="text-sm text-muted-foreground leading-relaxed">{description}</p>
          </div>
        </div>
      </Card>
    </motion.div>
  );
}


