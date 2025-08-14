"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";

const FormSchema = z.object({
  email: z.string().email("Enter a valid email"),
});

export function EmailLinkForm() {
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [message, setMessage] = useState<string>("");
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<{ email: string }>({ resolver: zodResolver(FormSchema) });

  async function onSubmit(values: { email: string }) {
    setStatus("loading");
    setMessage("");
    try {
      const link = process.env.NEXT_PUBLIC_APP_STORE_URL || "#";
      const res = await fetch("/api/email-link", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: values.email, link }),
      });
      const data = await res.json();
      if (data.ok) {
        setStatus("success");
        setMessage("Check your inbox for the link.");
        reset();
      } else {
        setStatus("error");
        setMessage(data.error || "Something went wrong.");
      }
    } catch {
      setStatus("error");
      setMessage("Could not send email. Try again later.");
    }
  }

  return (
    <form className="space-y-2" onSubmit={handleSubmit(onSubmit)} noValidate>
      <div className="space-y-1">
        <Label htmlFor="email">Email me the link</Label>
        <Input id="email" type="email" placeholder="you@example.com" {...register("email")} />
        {errors.email ? (
          <p className="text-xs text-red-600 mt-1">{errors.email.message}</p>
        ) : (
          <p className="text-xs text-muted-foreground mt-1">We’ll send you the App Store link.</p>
        )}
      </div>
      <Button type="submit" size="sm" disabled={status === "loading"}>
        {status === "loading" ? "Sending…" : "Send link"}
      </Button>
      {message && <div className="text-xs mt-1" aria-live="polite">{message}</div>}
    </form>
  );
}


