import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';
import { Check, TrendingDown } from 'lucide-react';

export function BundlePricing() {
  const bundle = {
    name: 'Pack Complet',
    tagline: 'Les 3 agents IA pour une couverture commerciale totale',
    agents: [
      { name: 'Louis', icon: '📞', description: 'Rappel automatique de leads' },
      { name: 'Arthur', icon: '🔄', description: 'Réactivation de bases dormantes' },
      { name: 'Alexandra', icon: '☎️', description: 'Réception d\'appels 24/7' },
    ],
    normalPrice: 970,
    bundlePrice: 890,
    savings: 80,
    savingsPercent: 8,
  };

  const benefits = [
    'Couverture complète : leads neufs, dormants et appels entrants',
    'Intégration CRM unifiée pour les 3 agents',
    'Dashboard consolidé avec reporting global',
    'Économie de 80€/mois par rapport aux abonnements séparés',
    'Support prioritaire dédié',
    'Onboarding accéléré (tous les agents configurés ensemble)',
  ];

  return (
    <section className="py-24 relative">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-purple-900/10 to-transparent" />

      <div className="container mx-auto px-4 relative z-10">
        {/* Header */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-green-500/10 border border-green-500/20 backdrop-blur-sm mb-6">
            <TrendingDown className="w-4 h-4 text-green-400" />
            <span className="text-sm font-semibold text-green-400">
              Économisez {bundle.savingsPercent}% avec le Pack Complet
            </span>
          </div>
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            <span className="text-white">Une équipe IA complète</span>
            <br />
            <span className="bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent">
              pour maximiser vos conversions
            </span>
          </h2>
          <p className="text-xl text-gray-300">
            Combinez les 3 agents et bénéficiez d&apos;une réduction immédiate
          </p>
        </div>

        {/* Bundle Card */}
        <div className="max-w-4xl mx-auto">
          <Card variant="gradient" className="p-10 bg-gradient-to-br from-violet-600/20 via-purple-600/20 to-pink-600/20 border-violet-500/30">
            <div className="grid md:grid-cols-2 gap-12">
              {/* Left: Pricing */}
              <div>
                <h3 className="text-3xl font-bold text-white mb-4">
                  {bundle.name}
                </h3>
                <p className="text-gray-300 mb-8">
                  {bundle.tagline}
                </p>

                {/* Prix */}
                <div className="mb-8">
                  <p className="text-gray-400 line-through text-xl mb-2">
                    {bundle.normalPrice}€ HT/mois
                  </p>
                  <div className="flex items-baseline gap-2 mb-2">
                    <span className="text-6xl font-bold text-white">
                      {bundle.bundlePrice}€
                    </span>
                    <span className="text-xl text-gray-400">
                      HT/mois
                    </span>
                  </div>
                  <p className="text-green-400 font-semibold text-lg">
                    💰 Économisez {bundle.savings}€ par mois
                  </p>
                </div>

                {/* Agents inclus */}
                <div className="space-y-3 mb-8">
                  <p className="text-sm font-semibold text-gray-400 uppercase tracking-wide">
                    Agents inclus
                  </p>
                  {bundle.agents.map((agent) => (
                    <div key={agent.name} className="flex items-center gap-3">
                      <span className="text-2xl">{agent.icon}</span>
                      <div>
                        <p className="font-semibold text-white">{agent.name}</p>
                        <p className="text-sm text-gray-400">{agent.description}</p>
                      </div>
                    </div>
                  ))}
                </div>

                <Button variant="primary" size="lg" className="w-full">
                  Démarrer avec le Pack Complet
                </Button>
              </div>

              {/* Right: Benefits */}
              <div className="space-y-4">
                <p className="text-sm font-semibold text-gray-400 uppercase tracking-wide mb-6">
                  Avantages du Pack
                </p>
                {benefits.map((benefit) => (
                  <div key={benefit} className="flex items-start gap-3">
                    <div className="flex-shrink-0 w-6 h-6 rounded-full bg-green-500/20 flex items-center justify-center">
                      <Check className="w-4 h-4 text-green-400" />
                    </div>
                    <p className="text-gray-300 leading-relaxed">{benefit}</p>
                  </div>
                ))}
              </div>
            </div>
          </Card>
        </div>

        {/* Footer Note */}
        <p className="text-center text-sm text-gray-400 mt-8">
          💡 Le Pack Complet inclut les 3 abonnements + consommation au réel (appels, SMS)
        </p>
      </div>
    </section>
  );
}
