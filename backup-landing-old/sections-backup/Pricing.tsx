'use client';

import { Check } from 'lucide-react';
import Link from 'next/link';

export default function Pricing() {
  return (
    <section id="tarifs" className="py-20 bg-black">
      <div className="max-w-5xl mx-auto px-4">
        {/* Header */}
        <div className="text-center mb-16">
          <h2 className="text-5xl font-bold mb-4">
            Tarifs transparents
          </h2>
          <p className="text-xl text-gray-300">
            Sans engagement • Sans frais cachés
          </p>
        </div>

        {/* Pricing Cards - Plus simple, référence à Solutions */}
        <div className="bg-white/10 backdrop-blur-lg border border-white/20 rounded-2xl p-12 text-center">
          <h3 className="text-3xl font-bold mb-6">
            Tarification à la consommation
          </h3>

          <div className="grid md:grid-cols-3 gap-8 mb-8">
            <div>
              <div className="text-4xl font-bold text-blue-400 mb-2">0,27€</div>
              <div className="text-gray-400">par minute d&apos;appel</div>
            </div>
            <div>
              <div className="text-4xl font-bold text-green-400 mb-2">0,14€</div>
              <div className="text-gray-400">par SMS envoyé</div>
            </div>
            <div>
              <div className="text-4xl font-bold text-violet-400 mb-2">Gratuit</div>
              <div className="text-gray-400">emails illimités</div>
            </div>
          </div>

          <div className="border-t border-white/10 pt-8 mb-8">
            <p className="text-lg text-gray-300 mb-4">
              Abonnements mensuels (hors consommation) :
            </p>
            <div className="flex justify-center gap-8 flex-wrap text-gray-300">
              <div><span className="font-bold text-blue-400">Louis</span> : 190€/mois</div>
              <div><span className="font-bold text-green-400">Arthur</span> : 390€/mois</div>
              <div><span className="font-bold text-violet-400">Pack</span> : 490€/mois</div>
            </div>
          </div>

          <div className="grid md:grid-cols-2 gap-6 text-left mb-8">
            <div className="flex items-start gap-2">
              <Check className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
              <span className="text-gray-300">Essai 14 jours gratuit (sans CB)</span>
            </div>
            <div className="flex items-start gap-2">
              <Check className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
              <span className="text-gray-300">Sans engagement</span>
            </div>
            <div className="flex items-start gap-2">
              <Check className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
              <span className="text-gray-300">Support français 24/7</span>
            </div>
            <div className="flex items-start gap-2">
              <Check className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
              <span className="text-gray-300">Déploiement en 5 jours</span>
            </div>
          </div>

          <Link
            href="#demo"
            className="inline-block px-12 py-4 bg-gradient-to-r from-blue-500 to-violet-500 rounded-xl font-bold text-lg hover:opacity-90 transition-opacity"
          >
            Commencer gratuitement →
          </Link>
        </div>

        {/* Note */}
        <p className="text-center text-gray-400 mt-8">
          Pour tout développement spécifique ou intégration avancée, <Link href="#demo" className="text-blue-400 hover:text-blue-300">contactez-nous</Link>.
        </p>
      </div>
    </section>
  );
}
