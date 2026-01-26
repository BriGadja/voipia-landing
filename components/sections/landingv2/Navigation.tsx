'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Menu, X } from 'lucide-react';

export default function Navigation() {
  const [isOpen, setIsOpen] = useState(false);
  const [showDropdown, setShowDropdown] = useState(false);

  return (
    <header className="sticky top-0 z-50 bg-black/95 backdrop-blur-md border-b border-white/10">
      {/* Header principal */}
      <div className="max-w-7xl mx-auto px-4 h-20 flex items-center justify-between">
        {/* Logo */}
        <Link href="/" className="flex items-center">
          <span className="text-2xl font-bold bg-gradient-to-r from-cyan-400 to-violet-400 bg-clip-text text-transparent">
            SABLIA VOX
          </span>
        </Link>

        {/* Navigation Desktop */}
        <nav className="hidden md:flex items-center gap-8">
          {/* Dropdown Solutions */}
          <div
            className="relative"
            onMouseEnter={() => setShowDropdown(true)}
            onMouseLeave={() => setShowDropdown(false)}
          >
            <button className="hover:text-blue-400 transition-colors">
              Solutions ▼
            </button>

            {showDropdown && (
              <div className="absolute top-full left-0 mt-2 w-80 bg-gray-900 border border-white/10 rounded-xl shadow-xl p-4 space-y-3">
                <Link href="#louis" className="block p-3 hover:bg-white/5 rounded-lg transition-colors">
                  <div className="font-semibold text-blue-400">📞 Rappel Automatique</div>
                  <div className="text-sm text-gray-400">Traitez vos leads entrants en 30 secondes</div>
                  <div className="text-xs text-gray-500 mt-1">190€/mois • En savoir plus →</div>
                </Link>

                <Link href="#arthur" className="block p-3 hover:bg-white/5 rounded-lg transition-colors">
                  <div className="font-semibold text-green-400">🔄 Relance Intelligente</div>
                  <div className="text-sm text-gray-400">Réactivez votre base dormante automatiquement</div>
                  <div className="text-xs text-gray-500 mt-1">390€/mois • En savoir plus →</div>
                </Link>

                <Link href="#pack" className="block p-3 hover:bg-white/5 rounded-lg border border-violet-500/20 transition-colors">
                  <div className="font-semibold text-violet-400">⚡ Pack Conversion</div>
                  <div className="text-sm text-gray-400">Automatisez 100% de votre pipeline</div>
                  <div className="text-xs text-gray-500 mt-1">490€/mois • En savoir plus →</div>
                </Link>
              </div>
            )}
          </div>

          <Link href="#comment-ca-marche" className="hover:text-blue-400 transition-colors">
            Comment ça marche
          </Link>
          <Link href="#tarifs" className="hover:text-blue-400 transition-colors">
            Tarifs
          </Link>
        </nav>

        {/* CTAs */}
        <div className="hidden md:flex items-center gap-3">
          <Link
            href="/login"
            className="px-5 py-2.5 bg-gradient-to-r from-violet-600 to-purple-600 rounded-lg font-semibold hover:opacity-90 transition-opacity text-sm"
          >
            Accéder à mes Dashboards
          </Link>
          <Link
            href="#demo"
            className="px-6 py-2.5 bg-gradient-to-r from-blue-500 to-violet-500 rounded-lg font-semibold hover:opacity-90 transition-opacity"
          >
            Démo Gratuite
          </Link>
        </div>

        {/* Mobile menu button */}
        <button className="md:hidden" onClick={() => setIsOpen(!isOpen)}>
          {isOpen ? <X /> : <Menu />}
        </button>
      </div>

      {/* Sous-header badges */}
      <div className="bg-white/5 border-t border-white/10 py-2">
        <div className="max-w-7xl mx-auto px-4 flex justify-center gap-8 text-sm text-gray-400 flex-wrap">
          <span>🇫🇷 100% Français</span>
          <span>⚡ Déploiement 5 jours</span>
          <span>🔒 RGPD</span>
          <span>🔓 Sans engagement</span>
        </div>
      </div>

      {/* Mobile menu (placeholder pour implémentation future) */}
      {isOpen && (
        <div className="md:hidden bg-black/95 backdrop-blur-md border-t border-white/10 p-4">
          <nav className="flex flex-col gap-4">
            <Link href="#louis" className="text-gray-300 hover:text-white transition-colors" onClick={() => setIsOpen(false)}>
              📞 Rappel Automatique
            </Link>
            <Link href="#arthur" className="text-gray-300 hover:text-white transition-colors" onClick={() => setIsOpen(false)}>
              🔄 Relance Intelligente
            </Link>
            <Link href="#pack" className="text-gray-300 hover:text-white transition-colors" onClick={() => setIsOpen(false)}>
              ⚡ Pack Conversion
            </Link>
            <Link href="#comment-ca-marche" className="text-gray-300 hover:text-white transition-colors" onClick={() => setIsOpen(false)}>
              Comment ça marche
            </Link>
            <Link href="#tarifs" className="text-gray-300 hover:text-white transition-colors" onClick={() => setIsOpen(false)}>
              Tarifs
            </Link>
            <Link
              href="/login"
              className="px-6 py-2.5 bg-gradient-to-r from-violet-600 to-purple-600 rounded-lg font-semibold hover:opacity-90 transition-opacity text-center"
              onClick={() => setIsOpen(false)}
            >
              Accéder à mes Dashboards
            </Link>
            <Link
              href="#demo"
              className="px-6 py-2.5 bg-gradient-to-r from-blue-500 to-violet-500 rounded-lg font-semibold hover:opacity-90 transition-opacity text-center"
              onClick={() => setIsOpen(false)}
            >
              Démo Gratuite
            </Link>
          </nav>
        </div>
      )}
    </header>
  );
}
