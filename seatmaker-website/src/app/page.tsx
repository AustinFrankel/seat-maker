import { Metadata } from "next";
import { AppStoreBadge } from "@/components/site/AppStoreBadge";
import Image from "next/image";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Seat Maker — Fast, Offline Seating Charts",
  description:
    "Design table layouts and drag guests into seats in seconds. Offline-ready, no login, share via QR. Download now on the App Store.",
};

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
      {/* Hero Section */}
      <section className="relative overflow-hidden">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-20">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div className="space-y-8">
              <div className="space-y-4">
                <h1 className="text-5xl lg:text-6xl font-bold tracking-tight text-gray-900 dark:text-white">
                  Create Perfect
                  <span className="block text-blue-600 dark:text-blue-400">
                    Seating Arrangements
                  </span>
                </h1>
                <p className="text-xl text-gray-600 dark:text-gray-300 max-w-2xl">
                  Design table layouts and drag guests into seats in seconds. 
                  Offline-ready, no login required, share via QR code.
                </p>
              </div>
              
              <div className="flex flex-col sm:flex-row gap-4">
                <AppStoreBadge />
                <Link 
                  href="/download" 
                  className="inline-flex items-center justify-center px-8 py-4 text-lg font-semibold text-blue-600 bg-white border-2 border-blue-600 rounded-xl hover:bg-blue-50 transition-colors"
                >
                  Learn More
                </Link>
              </div>
            </div>
            
            <div className="relative">
              <div className="relative z-10">
                <Image
                  src="/images/seat1.png"
                  alt="Seat Maker App Interface"
                  width={400}
                  height={600}
                  className="rounded-2xl shadow-2xl mx-auto"
                  priority
                />
              </div>
              <div className="absolute inset-0 bg-gradient-to-r from-blue-400/20 to-purple-400/20 rounded-2xl -z-10"></div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 bg-white dark:bg-gray-900">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-4">
              Why Choose Seat Maker?
            </h2>
            <p className="text-xl text-gray-600 dark:text-gray-300">
              The fastest way to organize your event seating
            </p>
          </div>
          
          <div className="grid md:grid-cols-3 gap-8">
            <div className="text-center space-y-4">
              <div className="w-16 h-16 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center mx-auto">
                <svg className="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white">Drag & Drop</h3>
              <p className="text-gray-600 dark:text-gray-300">
                Simply drag guests into seats with intuitive touch controls
              </p>
            </div>
            
            <div className="text-center space-y-4">
              <div className="w-16 h-16 bg-green-100 dark:bg-green-900 rounded-full flex items-center justify-center mx-auto">
                <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192L5.636 18.364M12 2.25a9.75 9.75 0 100 19.5 9.75 9.75 0 000-19.5z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white">Offline Ready</h3>
              <p className="text-gray-600 dark:text-gray-300">
                Works without internet - perfect for event venues
              </p>
            </div>
            
            <div className="text-center space-y-4">
              <div className="w-16 h-16 bg-purple-100 dark:bg-purple-900 rounded-full flex items-center justify-center mx-auto">
                <svg className="w-8 h-8 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white">QR Sharing</h3>
              <p className="text-gray-600 dark:text-gray-300">
                Share seating arrangements instantly via QR code
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* App Screenshots */}
      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-4">
              See Seat Maker in Action
            </h2>
            <p className="text-xl text-gray-600 dark:text-gray-300">
              Beautiful, intuitive interface designed for events
            </p>
          </div>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="space-y-4">
              <Image
                src="/images/seat1.png"
                alt="Round table seating"
                width={300}
                height={400}
                className="rounded-xl shadow-lg mx-auto"
              />
              <p className="text-center text-sm text-gray-600 dark:text-gray-400">Round Table Layout</p>
            </div>
            
            <div className="space-y-4">
              <Image
                src="/images/seat2.png"
                alt="Rectangle table seating"
                width={300}
                height={400}
                className="rounded-xl shadow-lg mx-auto"
              />
              <p className="text-center text-sm text-gray-600 dark:text-gray-400">Rectangle Table Layout</p>
            </div>
            
            <div className="space-y-4">
              <Image
                src="/images/seat3.png"
                alt="Square table seating"
                width={300}
                height={400}
                className="rounded-xl shadow-lg mx-auto"
              />
              <p className="text-center text-sm text-gray-600 dark:text-gray-400">Square Table Layout</p>
            </div>
            
            <div className="space-y-4">
              <Image
                src="/images/seat4.png"
                alt="Guest management"
                width={300}
                height={400}
                className="rounded-xl shadow-lg mx-auto"
              />
              <p className="text-center text-sm text-gray-600 dark:text-gray-400">Guest Management</p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 bg-blue-600 dark:bg-blue-700">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl font-bold text-white mb-6">
            Ready to Organize Your Event?
          </h2>
          <p className="text-xl text-blue-100 mb-8">
            Download Seat Maker today and create perfect seating arrangements in minutes
          </p>
          <AppStoreBadge />
        </div>
      </section>
    </div>
  );
}
