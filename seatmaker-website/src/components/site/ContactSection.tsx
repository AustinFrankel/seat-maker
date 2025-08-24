"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";

export default function ContactSection() {
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [status, setStatus] = useState<null | string>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setStatus("Sending…");
    try {
      const res = await fetch("/api/email-link", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, link: message }),
      });
      const data = await res.json();
      if (data.ok) {
        setStatus("Sent! I'll reply soon.");
        setEmail("");
        setMessage("");
      } else {
        setStatus("Failed to send. Try your mail app below.");
      }
    } catch {
      setStatus("Failed to send. Try your mail app below.");
    }
  }

  return (
    <section id="contact" className="py-20">
      <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
        <h2 className="text-3xl font-semibold tracking-tight text-center mb-8">Contact</h2>
        <p className="text-center text-muted-foreground mb-6">
          Questions or feedback? Email {" "}
          <a className="underline" href="mailto:austinhfrankel@gmail.com">austinhfrankel@gmail.com</a>
          {" "}or use the form below.
        </p>
        <form onSubmit={onSubmit} className="grid gap-4">
          <label className="grid gap-2">
            <span className="text-sm">Your email</span>
            <Input required type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" />
          </label>
          <label className="grid gap-2">
            <span className="text-sm">Message</span>
            <Textarea value={message} onChange={(e) => setMessage(e.target.value)} placeholder="How can I help?" />
          </label>
        
          <div className="flex items-center gap-3">
            <Button type="submit">Send</Button>
            <a
              className="text-sm underline"
              href={`mailto:austinhfrankel@gmail.com?subject=Seat%20Maker%20Contact&body=${encodeURIComponent(message)}`}
            >
              Open in Mail
            </a>
            {status && <span className="text-sm text-muted-foreground">{status}</span>}
          </div>
        </form>
      </div>
    </section>
  );
}


