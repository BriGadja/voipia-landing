'use client';

import { Card } from '@/components/shared/Card';
import { X, Check } from 'lucide-react';

const comparisons = [
  {
    without: 'Leads perdus ou non rappelés',
    with: 'Rappel instantané de chaque contact',
  },
  {
    without: 'Temps de réponse : plusieurs heures voire jours',
    with: 'Temps de réponse : moins de 60 secondes',
  },
  {
    without: 'Commerciaux surchargés de tâches administratives',
    with: 'IA qui qualifie et planifie automatiquement',
  },
  {
    without: 'Votre équipe passe 40% de son temps à rappeler',
    with: 'Votre équipe se concentre 100% sur la vente',
  },
  {
    without: 'Données éparpillées dans plusieurs outils',
    with: 'Dashboard et reporting unifié',
  },
];

export function ComparisonTable() {
  return (
    <section className="py-24 relative">
      <div className="container mx-auto px-4 relative z-10">

        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6 text-white">
            Pourquoi Louis transforme votre gestion des leads
          </h2>
          <p className="text-xl text-gray-300">
            Comparez votre processus actuel à ce que Louis peut faire pour vous.
          </p>
        </div>

        {/* Comparison table */}
        <Card variant="gradient" className="max-w-5xl mx-auto overflow-hidden">
          {/* Table header */}
          <div className="grid grid-cols-2 border-b border-white/10">
            <div className="p-6 bg-red-500/10 border-r border-white/10">
              <div className="flex items-center gap-2 justify-center">
                <X className="w-5 h-5 text-red-400" />
                <h3 className="font-bold text-white">Sans Louis</h3>
              </div>
            </div>
            <div className="p-6 bg-green-500/10">
              <div className="flex items-center gap-2 justify-center">
                <Check className="w-5 h-5 text-green-400" />
                <h3 className="font-bold text-white">Avec Louis</h3>
              </div>
            </div>
          </div>

          {/* Comparison rows */}
          {comparisons.map((comparison, idx) => (
            <div
              key={idx}
              className="grid grid-cols-2 border-b border-white/10 last:border-b-0"
            >
              {/* Without Louis */}
              <div className="p-6 bg-red-500/5 border-r border-white/10 flex items-center">
                <div className="flex items-start gap-3">
                  <X className="w-5 h-5 text-red-400 flex-shrink-0 mt-0.5" />
                  <p className="text-gray-300 text-sm">{comparison.without}</p>
                </div>
              </div>

              {/* With Louis */}
              <div className="p-6 bg-green-500/5 flex items-center">
                <div className="flex items-start gap-3">
                  <Check className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
                  <p className="text-gray-300 text-sm">{comparison.with}</p>
                </div>
              </div>
            </div>
          ))}
        </Card>

        {/* Bottom baseline */}
        <div className="text-center mt-8 max-w-3xl mx-auto">
          <p className="text-lg text-gray-300">
            Louis élimine les frictions et vous fait gagner jusqu&apos;à{' '}
            <span className="font-bold text-blue-400">35h par semaine</span> sur le rappel manuel.
          </p>
        </div>

      </div>
    </section>
  );
}
