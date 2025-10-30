'use client';

import { useState } from 'react';
import Link from 'next/link';
import { ChevronDown } from 'lucide-react';
import { getAllAgents } from '@/lib/data/agents';

export function Header() {
  const [isOpen, setIsOpen] = useState(false);
  const agents = getAllAgents();

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-black/80 backdrop-blur-lg border-b border-white/10">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link
            href="/"
            className="text-2xl font-bold bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent hover:from-violet-300 hover:to-purple-300 transition"
          >
            VoIPIA
          </Link>

          {/* Navigation Desktop */}
          <nav className="hidden md:flex items-center gap-8">
            {/* Dropdown Solutions */}
            <div
              className="relative"
              onMouseEnter={() => setIsOpen(true)}
              onMouseLeave={() => setIsOpen(false)}
            >
              <button className="flex items-center gap-2 text-gray-300 hover:text-white transition-colors">
                <span>Solutions</span>
                <ChevronDown className={`w-4 h-4 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
              </button>

              {/* Dropdown Menu */}
              {isOpen && (
                <div className="absolute top-full left-0 -mt-1 pt-3 pb-2">
                  <div className="w-80 bg-black/95 backdrop-blur-xl border border-white/10 rounded-lg p-4 shadow-2xl">
                    <div className="space-y-2">
                      {agents.map((agent) => (
                        <Link
                          key={agent.id}
                          href={`/${agent.id}`}
                          className="flex items-start gap-3 p-3 rounded-lg hover:bg-white/5 transition-colors group"
                        >
                          <span className="text-3xl">{agent.icon}</span>
                          <div className="flex-1">
                            <p className="font-semibold text-white group-hover:text-violet-400 transition-colors">
                              {agent.displayName}
                            </p>
                            <p className="text-sm text-gray-400">
                              {agent.tagline}
                            </p>
                          </div>
                        </Link>
                      ))}
                    </div>
                  </div>
                </div>
              )}
            </div>

            <Link href="/#tarifs" className="text-gray-300 hover:text-white transition-colors">
              Tarifs
            </Link>
            <Link href="/#faq" className="text-gray-300 hover:text-white transition-colors">
              FAQ
            </Link>
          </nav>

          {/* CTAs */}
          <div className="flex items-center gap-4">
            <Link
              href="/login"
              className="text-sm text-gray-300 hover:text-white transition-colors"
            >
              Connexion
            </Link>
            <Link
              href="/#contact"
              className="px-4 py-2 bg-gradient-to-r from-violet-600 to-purple-600 rounded-lg text-sm font-semibold hover:from-violet-700 hover:to-purple-700 transition-all hover:shadow-lg hover:shadow-violet-500/20"
            >
              TESTER NOS AGENTS
            </Link>
          </div>
        </div>
      </div>
    </header>
  );
}
