'use client';

import { Phone, RefreshCw, Zap, Check } from 'lucide-react';
import Link from 'next/link';

export default function Solutions() {
  const solutions = [
    {
      id: "louis",
      name: "Louis",
      icon: <Phone className="w-8 h-8" />,
      tagline: "Rappel Automatique",
      price: "190€",
      description: "Traitez vos leads entrants en moins de 30 secondes",
      color: "from-blue-500 to-blue-600",
      borderColor: "border-blue-500/30",
      features: [
        "Rappel instantané (< 30s)",
        "Qualification automatique",
        "Prise de RDV agenda",
        "Mise à jour CRM",
        "SMS de confirmation"
      ]
    },
    {
      id: "arthur",
      name: "Arthur",
      icon: <RefreshCw className="w-8 h-8" />,
      tagline: "Relance Intelligente",
      price: "390€",
      description: "Réactivez automatiquement votre base dormante",
      color: "from-green-500 to-green-600",
      borderColor: "border-green-500/30",
      features: [
        "Relance multicanal (appel + SMS + email)",
        "Scoring automatique des leads",
        "Gestion des NRP",
        "Réactivation base dormante",
        "Reporting détaillé"
      ]
    },
    {
      id: "pack",
      name: "Pack Conversion",
      icon: <Zap className="w-8 h-8" />,
      tagline: "Louis + Arthur",
      price: "490€",
      description: "Pipeline commercial 100% automatisé",
      color: "from-violet-500 to-violet-600",
      borderColor: "border-violet-500/30",
      badge: "Le plus populaire",
      features: [
        "Tout Louis + Tout Arthur",
        "Automatisation complète",
        "ROI maximum",
        "Support prioritaire",
        "Configuration sur-mesure"
      ]
    }
  ];

  return (
    <section id="solutions" className="py-20 bg-black">
      <div className="max-w-7xl mx-auto px-4">
        {/* Header */}
        <div className="text-center mb-16">
          <h2 className="text-5xl font-bold mb-4">
            Louis + Arthur = votre machine commerciale 100% automatisée
          </h2>
          <p className="text-xl text-gray-300">
            Choisissez la solution adaptée à vos besoins
          </p>
        </div>

        {/* Solutions Grid */}
        <div className="grid md:grid-cols-3 gap-8">
          {solutions.map((solution) => (
            <div
              key={solution.id}
              className={`relative bg-white/10 backdrop-blur-lg border ${solution.borderColor} rounded-2xl p-8 hover:scale-105 transition-transform`}
            >
              {/* Badge */}
              {solution.badge && (
                <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                  <div className="bg-gradient-to-r from-violet-500 to-pink-500 px-4 py-1 rounded-full text-sm font-bold">
                    ⭐ {solution.badge}
                  </div>
                </div>
              )}

              {/* Icon */}
              <div className={`w-16 h-16 bg-gradient-to-br ${solution.color} rounded-xl flex items-center justify-center mb-4`}>
                {solution.icon}
              </div>

              {/* Title */}
              <h3 className="text-3xl font-bold mb-2">{solution.name}</h3>
              <p className="text-gray-400 mb-6">{solution.tagline}</p>

              {/* Price */}
              <div className="mb-6">
                <div className="text-5xl font-bold mb-1">{solution.price}</div>
                <div className="text-gray-400">/mois • Sans engagement</div>
              </div>

              {/* Description */}
              <p className="text-gray-300 mb-6">{solution.description}</p>

              {/* Features */}
              <ul className="space-y-3 mb-8">
                {solution.features.map((feature, index) => (
                  <li key={index} className="flex items-start gap-2">
                    <Check className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
                    <span className="text-gray-300">{feature}</span>
                  </li>
                ))}
              </ul>

              {/* CTA */}
              <Link
                href="#demo"
                className={`block w-full py-3 bg-gradient-to-r ${solution.color} rounded-xl font-bold text-center hover:opacity-90 transition-opacity`}
              >
                Je veux {solution.name}
              </Link>
            </div>
          ))}
        </div>

        {/* Bottom CTA */}
        <div className="mt-12 text-center">
          <p className="text-gray-400 mb-4">
            Besoin d&apos;aide pour choisir ?
          </p>
          <Link
            href="#demo"
            className="inline-block px-8 py-4 bg-white/10 border border-white/20 rounded-xl font-semibold hover:bg-white/20 transition-colors"
          >
            Parler à un expert →
          </Link>
        </div>
      </div>
    </section>
  );
}
