'use client';

import { integrations } from '@/lib/data/integrations';
import Image from 'next/image';

export function IntegrationBar() {
  return (
    <section className="py-16 border-y border-white/5 bg-gradient-to-r from-transparent via-white/5 to-transparent">
      <div className="container mx-auto px-4">

        {/* Title */}
        <div className="text-center mb-12">
          <h2 className="text-sm font-semibold text-gray-400 uppercase tracking-wider mb-2">
            Intégrations natives
          </h2>
          <p className="text-lg text-gray-300">
            S&apos;intègre avec vos outils préférés en quelques clics
          </p>
        </div>

        {/* Scrolling logos */}
        <div className="relative overflow-hidden">
          {/* Fade effects */}
          <div className="absolute left-0 top-0 bottom-0 w-32 bg-gradient-to-r from-gray-950 to-transparent z-10" />
          <div className="absolute right-0 top-0 bottom-0 w-32 bg-gradient-to-l from-gray-950 to-transparent z-10" />

          {/* Logos container with animation */}
          <div className="flex gap-12 animate-scroll">
            {/* First set of logos */}
            {integrations.map((integration) => (
              <div
                key={`first-${integration.name}`}
                className="flex-shrink-0 flex items-center justify-center w-32 h-16 grayscale hover:grayscale-0 transition-all duration-300 opacity-50 hover:opacity-100"
              >
                {integration.logo ? (
                  <Image
                    src={integration.logo}
                    alt={integration.name}
                    width={120}
                    height={40}
                    className="object-contain"
                  />
                ) : (
                  <span className="text-gray-400 font-semibold text-sm">
                    {integration.name}
                  </span>
                )}
              </div>
            ))}
            {/* Duplicate set for seamless loop */}
            {integrations.map((integration) => (
              <div
                key={`second-${integration.name}`}
                className="flex-shrink-0 flex items-center justify-center w-32 h-16 grayscale hover:grayscale-0 transition-all duration-300 opacity-50 hover:opacity-100"
              >
                {integration.logo ? (
                  <Image
                    src={integration.logo}
                    alt={integration.name}
                    width={120}
                    height={40}
                    className="object-contain"
                  />
                ) : (
                  <span className="text-gray-400 font-semibold text-sm">
                    {integration.name}
                  </span>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Stats */}
        <div className="flex flex-wrap justify-center gap-8 mt-12 text-center">
          <div>
            <p className="text-3xl font-bold text-white">15+</p>
            <p className="text-sm text-gray-400">Intégrations natives</p>
          </div>
          <div>
            <p className="text-3xl font-bold text-white">API REST</p>
            <p className="text-sm text-gray-400">Webhooks disponibles</p>
          </div>
          <div>
            <p className="text-3xl font-bold text-white">99.9%</p>
            <p className="text-sm text-gray-400">Uptime garanti</p>
          </div>
        </div>

      </div>

      {/* Custom animation for scrolling */}
      <style jsx>{`
        @keyframes scroll {
          0% {
            transform: translateX(0);
          }
          100% {
            transform: translateX(-50%);
          }
        }
        .animate-scroll {
          animation: scroll 40s linear infinite;
        }
        .animate-scroll:hover {
          animation-play-state: paused;
        }
      `}</style>
    </section>
  );
}
