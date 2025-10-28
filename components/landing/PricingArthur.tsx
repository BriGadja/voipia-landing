'use client';

import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';
import { Check, Phone } from 'lucide-react';

const included = [
  'Infrastructure IA complète (serveur, ligne, hébergement)',
  'Séquences de relance personnalisées sur-mesure',
  'Dashboard VoIPIA + intégration CRM complète',
  'Transcriptions & scoring automatique',
  'Support et maintenance 24/7',
  'Déploiement en moins de 5 jours ouvrés',
];

const consumption = [
  { label: 'Appel téléphonique', price: '0,27 €/min' },
  { label: 'SMS de suivi', price: '0,14 €/SMS' },
  { label: 'Emails', price: 'Gratuits' },
];

export function PricingArthur() {
  return (
    <section className="py-24 relative">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-b from-orange-900/5 via-transparent to-orange-900/5" />

      <div className="container mx-auto px-4 relative z-10">
        {/* Section header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            <span className="text-white">Tarification</span>
            <br />
            <span className="bg-gradient-to-r from-orange-400 to-amber-400 bg-clip-text text-transparent">
              simple et transparente
            </span>
          </h2>
          <p className="text-xl text-gray-300">
            Aucun engagement. Arthur reste parce qu&apos;il génère du CA.
          </p>
        </div>

        {/* Pricing card */}
        <Card variant="gradient" className="max-w-4xl mx-auto overflow-hidden">
          {/* Main pricing */}
          <div className="p-8 md:p-12 border-b border-white/10">
            <div className="text-center mb-8">
              <div className="inline-flex items-baseline gap-2 mb-4">
                <span className="text-6xl md:text-7xl font-bold bg-gradient-to-r from-orange-400 to-amber-400 bg-clip-text text-transparent">
                  490 €
                </span>
                <span className="text-2xl text-gray-400">HT / mois</span>
              </div>
              <p className="text-gray-300">Abonnement mensuel</p>
            </div>

            {/* Included features */}
            <div className="space-y-4">
              <p className="font-semibold text-white mb-4">Inclus dans l&apos;abonnement :</p>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {included.map((feature, index) => (
                  <div key={index} className="flex items-start gap-3">
                    <div className="flex-shrink-0 w-5 h-5 rounded-full bg-orange-500/20 flex items-center justify-center mt-0.5">
                      <Check className="w-3 h-3 text-orange-400" />
                    </div>
                    <span className="text-sm text-gray-300">{feature}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Consumption */}
          <div className="p-8 md:p-12 bg-white/5 border-b border-white/10">
            <p className="font-semibold text-white mb-6">+ Consommation au réel</p>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {consumption.map((item, index) => (
                <div key={index} className="text-center">
                  <div className="w-12 h-12 rounded-full bg-orange-500/10 flex items-center justify-center mx-auto mb-3">
                    <Phone className="w-6 h-6 text-orange-400" />
                  </div>
                  <p className="text-sm text-gray-400 mb-2">{item.label}</p>
                  <p className="text-lg font-bold text-orange-400">{item.price}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Example calculation */}
          <div className="p-8 md:p-12">
            <div className="bg-orange-500/5 border border-orange-500/20 rounded-lg p-6">
              <p className="font-semibold text-white mb-4 flex items-center gap-2">
                <span className="text-orange-400">💡</span>
                Exemple pour une campagne de 1000 leads dormants/mois :
              </p>
              <div className="space-y-2 text-sm text-gray-300 mb-4">
                <div className="flex justify-between">
                  <span>• Abonnement mensuel</span>
                  <span className="font-semibold">490 € HT</span>
                </div>
                <div className="flex justify-between">
                  <span>• ~600 appels réussis (2,5 min/appel en moyenne)</span>
                  <span className="font-semibold">405 € HT</span>
                </div>
                <div className="flex justify-between">
                  <span>• ~200 SMS de suivi</span>
                  <span className="font-semibold">28 € HT</span>
                </div>
                <div className="h-px bg-white/10 my-3" />
                <div className="flex justify-between text-base font-bold text-white">
                  <span>= Total</span>
                  <span className="text-orange-400">923 € HT/mois</span>
                </div>
              </div>
              <div className="bg-gradient-to-r from-orange-500/20 to-amber-500/20 rounded-lg p-4 border border-orange-500/30">
                <p className="text-center">
                  <span className="text-gray-300">Pour un potentiel de </span>
                  <span className="text-2xl font-bold bg-gradient-to-r from-orange-400 to-amber-400 bg-clip-text text-transparent">
                    +40 000€
                  </span>
                  <span className="text-gray-300"> de CA généré sur votre base dormante</span>
                </p>
              </div>
            </div>

            {/* CTA */}
            <div className="text-center mt-8">
              <Button size="lg" className="bg-gradient-to-r from-orange-600 to-amber-600 hover:from-orange-700 hover:to-amber-700">
                <Phone className="w-5 h-5 mr-2" />
                Tester gratuitement Arthur
              </Button>
            </div>
          </div>

          {/* Baseline */}
          <div className="p-6 bg-orange-500/5 text-center border-t border-white/10">
            <p className="text-sm text-gray-300">
              Arthur s&apos;adapte à votre volume et à votre CRM. Déployé en moins de 5 jours, il se rentabilise dès la première campagne.
            </p>
          </div>
        </Card>
      </div>
    </section>
  );
}
