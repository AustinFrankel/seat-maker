import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy",
};

export default function PrivacyPage() {
  return (
    <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 py-10 md:py-16">
      <h1 className="text-3xl font-semibold tracking-tight">Privacy Policy</h1>
      <div className="text-sm text-muted-foreground mt-3 space-y-4">
        <p>Last updated: {new Date().toLocaleDateString()}</p>
        <p>
          Seat Maker is designed to work offline and store your data on your device (or in your iCloud if enabled).
          We do not collect, sell, or share personal information. No third-party tracking is included by default.
        </p>
        <p>
          If optional analytics are enabled via environment variables on the website, basic click and traffic data may be
          collected in aggregate. The app itself does not track usage.
        </p>
        <p>
          For any questions, contact <a className="underline" href="mailto:TableMakerContact@gmail.com">TableMakerContact@gmail.com</a>.
        </p>
      </div>
    </div>
  );
}


