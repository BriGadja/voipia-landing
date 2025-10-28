'use client';

import { Card } from '@/components/shared/Card';
import { Clock, PhoneCall, TrendingUp, Zap, ShieldCheck } from 'lucide-react';

const benefits = [
  { label: 'Délai moyen de rappel', value: '< 60 secondes', icon: Clock },
  { label: 'Taux de contact', value: '+72%', icon: PhoneCall },
  { label: 'Taux de conversion en RDV', value: 'x3', icon: TrendingUp },
  { label: 'Temps gagné', value: '+21h/semaine', icon: Zap },
  { label: 'Réduction du taux de perte', value: '-87%', icon: ShieldCheck },
];

export function BenefitsTable() {
  return (
    <section className="py-24 relative">
      <div className="container mx-auto px-4 relative z-10">

        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6 text-white">
            Des résultats qui parlent d&apos;eux-mêmes
          </h2>
          <p className="text-xl text-gray-300">
            Chaque lead est traité. Chaque opportunité est exploitée.
          </p>
        </div>

        {/* Benefits table */}
        <Card variant="gradient" className="max-w-4xl mx-auto overflow-hidden">
          <div className="divide-y divide-white/10">
            {benefits.map((benefit, idx) => (
              <div
                key={idx}
                className="p-6 flex items-center justify-between gap-6 hover:bg-white/5 transition-colors"
              >
                {/* Left: Label with icon */}
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-blue-500 to-cyan-500 flex items-center justify-center flex-shrink-0">
                    <benefit.icon className="w-5 h-5 text-white" />
                  </div>
                  <p className="text-gray-300 font-medium">
                    {benefit.label}
                  </p>
                </div>

                {/* Right: Value */}
                <p className="text-2xl md:text-3xl font-bold bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent whitespace-nowrap">
                  {benefit.value}
                </p>
              </div>
            ))}
          </div>
        </Card>

      </div>
    </section>
  );
}
