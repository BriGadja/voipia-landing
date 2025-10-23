'use client';

import { X, Check } from 'lucide-react';

export default function Comparison() {
  const comparisons = [
    { criteria: "Coût mensuel", human: "3 500€ (junior)", voipia: "490€ (Pack complet)" },
    { criteria: "Disponibilité", human: "35h/semaine", voipia: "24/7 sans pause" },
    { criteria: "Appels/jour", human: "40-60 appels", voipia: "Illimité" },
    { criteria: "Délai de rappel", human: "2h-24h", voipia: "< 30 secondes" },
    { criteria: "Taux d'erreur", human: "5-10%", voipia: "< 1%" },
    { criteria: "Formation requise", human: "2-3 mois", voipia: "5 jours" },
    { criteria: "Turnover", human: "Oui (démissions)", voipia: "Non" },
    { criteria: "Scalabilité", human: "Difficile", voipia: "Instantanée" }
  ];

  return (
    <section className="py-20 bg-gradient-to-b from-black to-violet-950/10">
      <div className="max-w-6xl mx-auto px-4">
        {/* Header */}
        <div className="text-center mb-16">
          <h2 className="text-5xl font-bold mb-4">
            Commercial humain vs VoIPIA
          </h2>
          <p className="text-xl text-gray-300">
            Comparez les performances
          </p>
        </div>

        {/* Comparison Table */}
        <div className="bg-white/10 backdrop-blur-lg border border-white/20 rounded-2xl overflow-hidden">
          {/* Header Row */}
          <div className="grid grid-cols-3 bg-white/5 border-b border-white/10">
            <div className="p-6 font-bold text-lg">Critère</div>
            <div className="p-6 font-bold text-lg border-l border-white/10 text-center">
              Commercial humain
            </div>
            <div className="p-6 font-bold text-lg border-l border-white/10 text-center bg-violet-500/10">
              VoIPIA
            </div>
          </div>

          {/* Comparison Rows */}
          {comparisons.map((comp, index) => (
            <div
              key={index}
              className={`grid grid-cols-3 ${index !== comparisons.length - 1 ? 'border-b border-white/10' : ''}`}
            >
              <div className="p-6 font-medium">{comp.criteria}</div>
              <div className="p-6 border-l border-white/10 text-center text-gray-400">
                {comp.human}
              </div>
              <div className="p-6 border-l border-white/10 text-center bg-violet-500/5 font-semibold text-violet-400">
                {comp.voipia}
              </div>
            </div>
          ))}
        </div>

        {/* Bottom Summary */}
        <div className="mt-12 grid md:grid-cols-2 gap-8">
          <div className="bg-red-950/20 backdrop-blur-lg border border-red-500/30 rounded-2xl p-8">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 bg-red-500/10 rounded-full flex items-center justify-center">
                <X className="w-6 h-6 text-red-400" />
              </div>
              <h3 className="text-2xl font-bold text-red-400">Commercial humain</h3>
            </div>
            <ul className="space-y-2 text-gray-300">
              <li>• Coûts fixes élevés (salaire + charges)</li>
              <li>• Disponibilité limitée</li>
              <li>• Fatigue et variations de performance</li>
              <li>• Formation longue et turnover</li>
            </ul>
          </div>

          <div className="bg-green-950/20 backdrop-blur-lg border border-green-500/30 rounded-2xl p-8">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 bg-green-500/10 rounded-full flex items-center justify-center">
                <Check className="w-6 h-6 text-green-400" />
              </div>
              <h3 className="text-2xl font-bold text-green-400">VoIPIA</h3>
            </div>
            <ul className="space-y-2 text-gray-300">
              <li>• Coût fixe prévisible</li>
              <li>• Disponible 24/7 sans pause</li>
              <li>• Performance constante et optimale</li>
              <li>• Déploiement en 5 jours</li>
            </ul>
          </div>
        </div>
      </div>
    </section>
  );
}
