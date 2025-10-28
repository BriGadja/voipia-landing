'use client';

import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';
import { pricing } from '@/lib/data/pricing';
import { Check, Sparkles } from 'lucide-react';
import Link from 'next/link';

export function PricingCardsHome() {
  return (
    <section className="py-24 relative">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-b from-violet-900/5 via-purple-900/10 to-violet-900/5" />

      <div className="container mx-auto px-4 relative z-10">

        {/* Section header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-green-500/10 border border-green-500/20 backdrop-blur-sm mb-6">
            <Sparkles className="w-4 h-4 text-green-400" />
            <span className="text-sm font-semibold text-green-300">
              Tarification transparente
            </span>
          </div>
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            <span className="text-white">Un prix juste,</span>
            <br />
            <span className="bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent">
              pas de mauvaises surprises
            </span>
          </h2>
          <p className="text-xl text-gray-300">
            Choisissez l&apos;agent qui correspond à vos besoins. Changez ou combinez à tout moment.
          </p>
        </div>

        {/* Pricing cards */}
        <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {pricing.map((tier) => {
            const isPopular = tier.badge === 'Populaire';

            return (
              <Card
                key={tier.agentType}
                variant="gradient"
                className={`p-8 flex flex-col relative ${
                  isPopular ? 'border-2 border-violet-500/50 shadow-2xl shadow-violet-500/20 scale-105' : ''
                }`}
              >
                {/* Popular badge */}
                {isPopular && (
                  <div className="absolute -top-4 left-1/2 -translate-x-1/2 px-4 py-1 rounded-full bg-gradient-to-r from-violet-600 to-purple-600 text-white text-xs font-bold">
                    ⭐ {tier.badge}
                  </div>
                )}

                {/* Header */}
                <div className="text-center mb-8">
                  <h3 className="text-2xl font-bold text-white mb-2">
                    {tier.name}
                  </h3>
                  <div className="flex items-baseline justify-center gap-2 mb-4">
                    <span className={`text-5xl font-bold bg-gradient-to-r ${tier.color?.gradient || 'from-violet-400 to-purple-400'} bg-clip-text text-transparent`}>
                      {tier.price}€
                    </span>
                    <span className="text-gray-400 text-sm">
                      /{tier.period === 'month' ? 'mois' : 'an'}
                    </span>
                  </div>
                  <p className="text-gray-300 text-sm">
                    {tier.description || `Agent ${tier.name} tout compris`}
                  </p>
                </div>

                {/* Features */}
                <div className="flex-grow mb-8">
                  <ul className="space-y-3">
                    {tier.included.map((feature, idx) => (
                      <li key={idx} className="flex items-start gap-3">
                        <Check className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
                        <span className="text-gray-300 text-sm">{feature}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                {/* Consumption info */}
                <div className="bg-black/20 rounded-lg p-4 mb-6 border border-white/5">
                  <p className="text-xs text-gray-400 mb-2 font-semibold">
                    Consommation moyenne :
                  </p>
                  <div className="grid grid-cols-3 gap-2 text-center">
                    <div>
                      <p className="text-xs text-gray-500">Appels</p>
                      <p className="text-sm font-bold text-white">{tier.consumption.calls}</p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500">SMS</p>
                      <p className="text-sm font-bold text-white">{tier.consumption.sms}</p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500">Emails</p>
                      <p className="text-sm font-bold text-white">{tier.consumption.emails}</p>
                    </div>
                  </div>
                </div>

                {/* Example (if available) */}
                {tier.example && (
                  <div className="bg-white/5 rounded-lg p-4 mb-6 border border-white/10">
                    <p className="text-xs text-gray-400 mb-2">
                      Exemple : {tier.example.volume}
                    </p>
                    <div className="space-y-1 text-xs">
                      <div className="flex justify-between">
                        <span className="text-gray-400">Abonnement</span>
                        <span className="text-white font-semibold">{tier.example.breakdown.subscription}€</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-400">Consommation</span>
                        <span className="text-white font-semibold">
                          {tier.example.breakdown.calls + tier.example.breakdown.sms}€
                        </span>
                      </div>
                      <div className="flex justify-between border-t border-white/10 pt-1 mt-2">
                        <span className="text-white font-bold">Total</span>
                        <span className={`font-bold bg-gradient-to-r ${tier.color?.gradient || 'from-violet-400 to-purple-400'} bg-clip-text text-transparent`}>
                          {tier.example.breakdown.total}€
                        </span>
                      </div>
                    </div>
                  </div>
                )}

                {/* CTA */}
                <Button
                  variant={isPopular ? 'primary' : 'outline'}
                  size="lg"
                  className="w-full"
                  asChild
                >
                  <Link href={`/${tier.agentType}`}>
                    {tier.cta.label || tier.cta.text}
                  </Link>
                </Button>
              </Card>
            );
          })}
        </div>

        {/* Bottom note */}
        <div className="text-center mt-12 space-y-4">
          <p className="text-sm text-gray-400">
            💡 Combinez plusieurs agents pour bénéficier de tarifs dégressifs
          </p>
          <p className="text-sm text-gray-400">
            Toutes les formules incluent : Support 7j/7, API illimitée, Intégrations natives
          </p>
        </div>

      </div>
    </section>
  );
}
