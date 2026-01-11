'use client';

import Link from 'next/link';
import { Mail, Phone, MapPin } from 'lucide-react';

export default function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="bg-black border-t border-white/10">
      <div className="max-w-7xl mx-auto px-4 py-16">
        <div className="grid md:grid-cols-4 gap-12 mb-12">
          {/* Col 1: Logo + Description */}
          <div>
            <div className="text-2xl font-bold bg-gradient-to-r from-blue-500 to-violet-500 bg-clip-text text-transparent mb-4">
              VOIPIA
            </div>
            <p className="text-gray-400 mb-4">
              Automatisez votre CRM avec des agents vocaux IA. Vos leads rappelés en 30 secondes.
            </p>
            <div className="flex gap-4">
              <a href="https://linkedin.com" target="_blank" rel="noopener noreferrer" className="w-10 h-10 bg-white/10 rounded-lg flex items-center justify-center hover:bg-white/20 transition-colors">
                💼
              </a>
              <a href="https://twitter.com" target="_blank" rel="noopener noreferrer" className="w-10 h-10 bg-white/10 rounded-lg flex items-center justify-center hover:bg-white/20 transition-colors">
                𝕏
              </a>
            </div>
          </div>

          {/* Col 2: Solutions */}
          <div>
            <h3 className="font-bold text-lg mb-4">Solutions</h3>
            <ul className="space-y-3 text-gray-400">
              <li><Link href="#louis" className="hover:text-white transition-colors">Louis - Rappel Automatique</Link></li>
              <li><Link href="#arthur" className="hover:text-white transition-colors">Arthur - Relance Intelligente</Link></li>
              <li><Link href="#pack" className="hover:text-white transition-colors">Pack Conversion</Link></li>
              <li><Link href="#roi-calculator" className="hover:text-white transition-colors">Calculateur ROI</Link></li>
            </ul>
          </div>

          {/* Col 3: Ressources */}
          <div>
            <h3 className="font-bold text-lg mb-4">Ressources</h3>
            <ul className="space-y-3 text-gray-400">
              <li><Link href="#comment-ca-marche" className="hover:text-white transition-colors">Comment ça marche</Link></li>
              <li><Link href="#tarifs" className="hover:text-white transition-colors">Tarifs</Link></li>
              <li><Link href="/login" className="hover:text-white transition-colors">Dashboard Client</Link></li>
              <li><Link href="#demo" className="hover:text-white transition-colors">Demander une démo</Link></li>
            </ul>
          </div>

          {/* Col 4: Contact */}
          <div>
            <h3 className="font-bold text-lg mb-4">Contact</h3>
            <ul className="space-y-3 text-gray-400">
              <li className="flex items-center gap-2">
                <Mail className="w-4 h-4 text-blue-400" />
                <a href="mailto:brice@sablia.io" className="hover:text-white transition-colors">brice@sablia.io</a>
              </li>
              <li className="flex items-center gap-2">
                <Phone className="w-4 h-4 text-blue-400" />
                <a href="tel:+33XXXXXXXXX" className="hover:text-white transition-colors">09 XX XX XX XX</a>
              </li>
              <li className="flex items-start gap-2">
                <MapPin className="w-4 h-4 text-blue-400 flex-shrink-0 mt-1" />
                <span>Paris, France<br />🇫🇷 100% Français</span>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="pt-8 border-t border-white/10">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4 text-sm text-gray-400">
            <div>
              © {currentYear} Voipia. Tous droits réservés.
            </div>
            <div className="flex gap-6">
              <Link href="/mentions-legales" className="hover:text-white transition-colors">Mentions légales</Link>
              <Link href="/cgv" className="hover:text-white transition-colors">CGV</Link>
              <Link href="/confidentialite" className="hover:text-white transition-colors">Confidentialité</Link>
            </div>
          </div>
        </div>

        {/* Bandeau final */}
        <div className="mt-8 text-center text-sm text-gray-500">
          Pour tout développement spécifique ou intégration avancée, <Link href="#demo" className="text-blue-400 hover:text-blue-300">contactez-nous</Link>.
        </div>
      </div>
    </footer>
  );
}
