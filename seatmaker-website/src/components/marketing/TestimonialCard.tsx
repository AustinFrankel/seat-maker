import { Card } from "@/components/ui/card";

export function TestimonialCard({
  quote,
  author,
}: {
  quote: string;
  author: string;
}) {
  return (
    <Card className="p-5 h-full">
      <blockquote className="text-sm leading-relaxed">“{quote}”</blockquote>
      <div className="mt-3 text-xs text-muted-foreground">— {author}</div>
    </Card>
  );
}


