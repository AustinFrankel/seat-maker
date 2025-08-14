import { Card } from "@/components/ui/card";

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
    <div className="group">
      <Card className="p-5 h-full transition-all duration-300 hover:shadow-lg hover:shadow-primary/10 border-primary/20 hover:border-primary/40 hover:-translate-y-1">
        <div className="flex items-start gap-3">
          {icon ? (
            <div className="mt-0.5 text-primary transition-transform duration-300 group-hover:rotate-3 group-hover:scale-110">
              {icon}
            </div>
          ) : null}
          <div>
            <h3 className="text-sm font-semibold leading-none mb-2 transition-transform duration-300 group-hover:translate-x-1">
              {title}
            </h3>
            <p className="text-sm text-muted-foreground leading-relaxed">{description}</p>
          </div>
        </div>
      </Card>
    </div>
  );
}


