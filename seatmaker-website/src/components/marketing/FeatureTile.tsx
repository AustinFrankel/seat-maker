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
    <Card className="p-5 h-full transition hover:shadow-md hover:-translate-y-0.5">
      <div className="flex items-start gap-3">
        {icon ? <div className="mt-0.5 text-primary">{icon}</div> : null}
        <div>
          <h3 className="text-sm font-semibold leading-none mb-2">{title}</h3>
          <p className="text-sm text-muted-foreground leading-relaxed">{description}</p>
        </div>
      </div>
    </Card>
  );
}


