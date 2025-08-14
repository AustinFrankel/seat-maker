import { Metadata } from "next";
import { AppStoreBadge } from "@/components/site/AppStoreBadge";
import { DeviceMockups } from "@/components/site/DeviceMockups";
import { FeatureTile } from "@/components/marketing/FeatureTile";
import { TestimonialCard } from "@/components/marketing/TestimonialCard";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";
import { DemoLink } from "@/components/site/DemoLink";
import Image from "next/image";
import QRCode from "react-qr-code";
import { motion } from "framer-motion";

export const metadata: Metadata = {
  title: "Download Seat Maker — Fast, Offline Seating Charts",
  description:
    "Design table layouts and drag guests into seats in seconds. Offline-ready, no login, share via QR. Download now on the App Store.",
};

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.2,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.6,
      ease: "easeOut",
    },
  },
};

const fadeInUp = {
  hidden: { opacity: 0, y: 30 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.8,
      ease: "easeOut",
    },
  },
};

export default function DownloadPage() {
  const appStoreUrl = process.env.NEXT_PUBLIC_APP_STORE_URL || "https://apps.apple.com/us/app/seat-maker/id6748284141";
  
  return (
    <div className="">
      {/* Hero Section */}
      <section className="pt-10 md:pt-16">
        <motion.div 
          className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 grid md:grid-cols-2 gap-10 items-center"
          variants={containerVariants}
          initial="hidden"
          animate="visible"
        >
          <motion.div variants={itemVariants}>
            <motion.div 
              className="inline-flex items-center gap-2 rounded-full bg-secondary px-3 py-1 text-xs"
              whileHover={{ scale: 1.05 }}
              transition={{ type: "spring", stiffness: 400, damping: 10 }}
            >
              <Badge variant="secondary">New</Badge>
              Seat Maker v1.2 — Offline, no login
            </motion.div>
            <motion.h1 
              className="text-3xl md:text-5xl font-semibold tracking-tight mt-4"
              variants={fadeInUp}
            >
              Plan perfect seating in minutes
            </motion.h1>
            <motion.p 
              className="text-muted-foreground mt-4 max-w-prose"
              variants={fadeInUp}
            >
              Seat Maker lets you design table layouts and assign seats fast. Works fully offline, no account required. Drag & drop guests, lock VIPs, shuffle layouts, and share via QR.
            </motion.p>
            <motion.div 
              className="flex items-center gap-4 mt-6"
              variants={itemVariants}
            >
              <AppStoreBadge />
              <DemoLink />
            </motion.div>
            <motion.div 
              className="mt-6 flex items-center gap-4 text-xs text-muted-foreground"
              variants={itemVariants}
            >
              <span>★ ★ ★ ★ ★</span>
              <span>Trusted by event planners</span>
            </motion.div>
          </motion.div>
          <motion.div variants={itemVariants}>
            <DeviceMockups />
          </motion.div>
        </motion.div>
      </section>

      {/* Features Section */}
      <section className="py-12 md:py-16">
        <motion.div 
          className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8"
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.3 }}
        >
          <motion.div 
            className="grid sm:grid-cols-2 md:grid-cols-3 gap-4"
            variants={containerVariants}
          >
            <motion.div variants={itemVariants} whileHover={{ scale: 1.02 }}>
              <FeatureTile title="Why it's fast" description="Offline-ready, no login, instant drag-and-drop seating." />
            </motion.div>
            <motion.div variants={itemVariants} whileHover={{ scale: 1.02 }}>
              <FeatureTile title="Contact import" description="Quickly bring in guests from Contacts to speed up setup." />
            </motion.div>
            <motion.div variants={itemVariants} whileHover={{ scale: 1.02 }}>
              <FeatureTile title="Shuffle & lock" description="Randomize seating then lock VIPs in place." />
            </motion.div>
            <motion.div variants={itemVariants} whileHover={{ scale: 1.02 }}>
              <FeatureTile title="QR sharing" description="Share plans via QR so others can view instantly." />
            </motion.div>
            <motion.div variants={itemVariants} whileHover={{ scale: 1.02 }}>
              <FeatureTile title="Share easily" description="Share links or images with venues and guests." />
            </motion.div>
            <motion.div variants={itemVariants} whileHover={{ scale: 1.02 }}>
              <FeatureTile title="Works offline" description="No connectivity required. Your data stays on device." />
            </motion.div>
          </motion.div>
          
          <motion.div 
            variants={fadeInUp}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
          >
            <Separator className="my-10" />
          </motion.div>
          
          <motion.div 
            className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4"
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, amount: 0.2 }}
          >
            {[1,2,3,4,5].map((n, index) => (
              <motion.div 
                key={n} 
                className="relative aspect-[9/16] rounded-xl overflow-hidden border"
                variants={itemVariants}
                whileHover={{ scale: 1.05, rotateY: 5 }}
                transition={{ type: "spring", stiffness: 300, damping: 20 }}
                style={{ animationDelay: `${index * 0.1}s` }}
              >
                <Image
                  src={`/images/seat${n}.png`}
                  alt={`Seat Maker showcase ${n}`}
                  fill
                  sizes="(max-width: 768px) 50vw, 20vw"
                  className="object-contain bg-background"
                />
              </motion.div>
            ))}
          </motion.div>
        </motion.div>
      </section>

      {/* Testimonials Section */}
      <section className="py-12 md:py-16 bg-secondary/40" id="demo">
        <motion.div 
          className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 grid md:grid-cols-4 gap-4"
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.3 }}
        >
          <motion.div variants={itemVariants} whileHover={{ y: -5 }}>
            <TestimonialCard quote="Made my wedding layout in under 10 minutes!" author="Emily, Bride" />
          </motion.div>
          <motion.div variants={itemVariants} whileHover={{ y: -5 }}>
            <TestimonialCard quote="The offline mode is a lifesaver on-site." author="Alex, Event Planner" />
          </motion.div>
          <motion.div variants={itemVariants} whileHover={{ y: -5 }}>
            <TestimonialCard quote="The QR sharing is so slick." author="Taylor, Venue Manager" />
          </motion.div>
          <motion.div variants={itemVariants} whileHover={{ y: -5 }}>
            <TestimonialCard quote="Clean, intuitive, and fast." author="Jordan, Coordinator" />
          </motion.div>
        </motion.div>
      </section>

      {/* Download Section */}
      <section className="py-12 md:py-16">
        <motion.div 
          className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 grid md:grid-cols-2 gap-10 items-center"
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.3 }}
        >
          <motion.div variants={itemVariants}>
            <h2 className="text-2xl font-semibold tracking-tight">Download Seat Maker v1.2</h2>
            <p className="text-muted-foreground mt-2">
              Ready to simplify your seating arrangements? Get Seat Maker on the App Store today and start creating the
              perfect seating chart for your next event.
            </p>
            <motion.div 
              className="mt-6 flex items-center gap-4"
              whileHover={{ scale: 1.02 }}
            >
              <AppStoreBadge />
            </motion.div>
            <div className="mt-6 text-sm text-muted-foreground">
              Compatible with iPhone and iPad. Works offline. No account required.
            </div>
          </motion.div>
          <motion.div 
            className="flex items-center justify-center"
            variants={itemVariants}
            whileHover={{ scale: 1.05 }}
            transition={{ type: "spring", stiffness: 300, damping: 20 }}
          >
            <div className="rounded-xl bg-white p-4 shadow-sm border">
              <QRCode value={appStoreUrl} size={180} aria-label="QR code to download Seat Maker" />
            </div>
          </motion.div>
        </motion.div>
      </section>

      {/* Features Detail Section */}
      <section className="py-12 md:py-16">
        <motion.div 
          className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 grid md:grid-cols-2 gap-10 items-start"
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.3 }}
        >
          <motion.div variants={itemVariants}>
            <motion.h2 
              className="text-2xl font-semibold tracking-tight"
              whileHover={{ x: 5 }}
              transition={{ type: "spring", stiffness: 400, damping: 10 }}
            >
              Custom Tables
            </motion.h2>
            <p className="text-muted-foreground mt-2">
              Design custom tables, square, circular, or rectangular, then randomize seating or move guests manually for the perfect arrangement.
            </p>
            
            <motion.h2 
              className="text-2xl font-semibold tracking-tight mt-6"
              whileHover={{ x: 5 }}
              transition={{ type: "spring", stiffness: 400, damping: 10 }}
            >
              Build Profiles
            </motion.h2>
            <p className="text-muted-foreground mt-2">
              Create guest profiles with names, comments, and photos to organize your event's party seating list effectively.
            </p>
            
            <motion.h2 
              className="text-2xl font-semibold tracking-tight mt-6"
              whileHover={{ x: 5 }}
              transition={{ type: "spring", stiffness: 400, damping: 10 }}
            >
              Export and Share
            </motion.h2>
            <p className="text-muted-foreground mt-2">
              Share your seating plan instantly via message or QR code so friends, family, or your venue can view it immediately.
            </p>
            
            <motion.h2 
              className="text-2xl font-semibold tracking-tight mt-6"
              whileHover={{ x: 5 }}
              transition={{ type: "spring", stiffness: 400, damping: 10 }}
            >
              View History
            </motion.h2>
            <p className="text-muted-foreground mt-2">
              Access past seating layouts to reuse or update previous table setups for your events and parties.
            </p>
            
            <motion.h2 
              className="text-2xl font-semibold tracking-tight mt-6"
              whileHover={{ x: 5 }}
              transition={{ type: "spring", stiffness: 400, damping: 10 }}
            >
              Personalize and Settings
            </motion.h2>
            <p className="text-muted-foreground mt-2">
              Adjust appearance, table settings, view event statistics, and manage profiles and other preferences to tailor your seating experience.
            </p>
          </motion.div>
          <motion.div 
            className="relative aspect-video rounded-xl overflow-hidden border"
            variants={itemVariants}
            whileHover={{ scale: 1.02, rotateY: 2 }}
            transition={{ type: "spring", stiffness: 300, damping: 20 }}
          >
            <Image src="/images/seat3.png" alt="Seat Maker app screenshot" fill className="object-contain bg-background" />
          </motion.div>
        </motion.div>
      </section>
    </div>
  );
}


