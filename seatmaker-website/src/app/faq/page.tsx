import { Metadata } from "next";
import FAQClient from "./faq-client";

export const metadata: Metadata = {
  title: "FAQ",
  description: "Answers about getting started, tables & guests, sharing/export, privacy/offline, payments.",
};

export default function FAQPage() {
  return <FAQClient />;
}