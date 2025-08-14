import { Card } from "@/components/ui/card";

export function TestimonialCard({
  quote,
  author,
}: {
  quote: string;
  author: string;
}) {
  return (
    <div className="group">
      <Card className="p-5 h-full transition-all duration-300 hover:shadow-lg hover:shadow-secondary/20 border-secondary/20 hover:border-secondary/40 hover:-translate-y-1">
        <blockquote className="text-sm leading-relaxed transition-transform duration-300 group-hover:translate-x-1">
          &ldquo;{quote}&rdquo;
        </blockquote>
        <div className="mt-3 text-xs text-muted-foreground transition-transform duration-300 group-hover:translate-x-1">
          — {author}
        </div>
      </Card>
    </div>
  );
}


