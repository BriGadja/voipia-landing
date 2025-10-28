'use client';

import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';
import { Check, Phone, MessageSquare, Mail } from 'lucide-react';

export function PricingLouis() {
  return (
    <section className="py-24 relative">
      <div className="container mx-auto px-4 relative z-10">

        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6 text-white">
            Tarification simple et transparente
          </h2>
          <p className="text-xl text-gray-300">
            Aucun engagement. Louis reste parce qu&apos;il performe.
          </p>
        </div>

        {/* Pricing card */}
        <Card variant="gradient" className="max-w-3xl mx-auto p-10 border-2 border-blue-500/30">
          {/* Main price */}
          <div className="text-center mb-10">
            <div className="inline-flex items-baseline gap-2 mb-4">
              <span className="text-6xl font-bold bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent">
                190€
              </span>
              <span className="text-gray-400 text-lg">HT / mois</span>
            </div>
            <p className="text-gray-300">Infrastructure IA complète incluse</p>
          </div>

          {/* Included features */}
          <div className="space-y-4 mb-10">
            <p className="font-bold text-white mb-4">Inclus dans l&apos;abonnement :</p>
            {[
              'Infrastructure IA complète (serveur, ligne, hébergement)',
              'Scénario vocal personnalisé sur-mesure',
              'Dashboard VoIPIA + intégration CRM complète',
              'Transcriptions & scoring automatique',
              'Support et maintenance 24/7',
              'Déploiement en moins de 5 jours ouvrés',
            ].map((feature, idx) => (
              <div key={idx} className="flex items-start gap-3">
                <Check className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
                <span className="text-gray-300 text-sm">{feature}</span>
              </div>
            ))}
          </div>

          {/* Consumption pricing */}
          <div className="bg-black/20 rounded-lg p-6 mb-8 border border-white/10">
            <p className="font-bold text-white mb-4">+ Consommation au réel</p>
            <div className="grid md:grid-cols-3 gap-4">
              <div className="flex items-start gap-3">
                <Phone className="w-5 h-5 text-blue-400 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold text-white text-sm">0,27€ / minute</p>
                  <p className="text-xs text-gray-400">Appel</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <MessageSquare className="w-5 h-5 text-blue-400 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold text-white text-sm">0,14€ / SMS</p>
                  <p className="text-xs text-gray-400">SMS</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <Mail className="w-5 h-5 text-blue-400 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold text-white text-sm">Gratuit</p>
                  <p className="text-xs text-gray-400">Emails</p>
                </div>
              </div>
            </div>
          </div>

          {/* Example calculation */}
          <div className="bg-blue-500/10 rounded-lg p-6 mb-8 border border-blue-500/20">
            <p className="font-bold text-blue-300 mb-4">📊 Exemple pour 300 leads/mois :</p>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between text-gray-300">
                <span>Abonnement mensuel</span>
                <span className="font-semibold">190€ HT</span>
              </div>
              <div className="flex justify-between text-gray-300">
                <span>~300 appels (2 min/appel en moyenne)</span>
                <span className="font-semibold">162€ HT</span>
              </div>
              <div className="flex justify-between text-gray-300">
                <span>~40 SMS de confirmation</span>
                <span className="font-semibold">5,60€ HT</span>
              </div>
              <div className="flex justify-between pt-2 mt-2 border-t border-blue-500/20">
                <span className="font-bold text-white">Total</span>
                <span className="font-bold text-blue-400">357,60€ HT/mois</span>
              </div>
            </div>
          </div>

          {/* CTA */}
          <div className="text-center">
            <Button size="lg" className="w-full md:w-auto bg-gradient-to-r from-blue-600 to-cyan-600 hover:from-blue-700 hover:to-cyan-700">
              Tester Louis gratuitement
            </Button>
            <p className="text-xs text-gray-400 mt-4">
              Louis s&apos;adapte à votre volume. Payez uniquement ce que vous consommez.
            </p>
          </div>
        </Card>

      </div>
    </section>
  );
}
