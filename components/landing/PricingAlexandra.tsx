'use client';

import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';
import { Check, Phone, MessageSquare, Mail } from 'lucide-react';

export function PricingAlexandra() {
  return (
    <section className="py-24 relative">
      <div className="container mx-auto px-4 relative z-10">

        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6 text-white">
            Tarification simple et transparente
          </h2>
          <p className="text-xl text-gray-300">
            Aucun engagement. Alexandra reste parce qu&apos;elle performe.
          </p>
        </div>

        {/* Pricing card */}
        <Card variant="gradient" className="max-w-3xl mx-auto p-10 border-2 border-green-500/30">
          {/* Main price */}
          <div className="text-center mb-10">
            <div className="inline-flex items-baseline gap-2 mb-4">
              <span className="text-6xl font-bold bg-gradient-to-r from-green-400 to-emerald-400 bg-clip-text text-transparent">
                290€
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
              'Base de connaissances personnalisée sur-mesure',
              'Dashboard VoIPIA + intégration CRM complète',
              'Transcriptions & catégorisation automatique',
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
                <Phone className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold text-white text-sm">0,27€ / minute</p>
                  <p className="text-xs text-gray-400">Appel</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <MessageSquare className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold text-white text-sm">0,14€ / SMS</p>
                  <p className="text-xs text-gray-400">SMS</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <Mail className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold text-white text-sm">Gratuit</p>
                  <p className="text-xs text-gray-400">Emails</p>
                </div>
              </div>
            </div>
          </div>

          {/* Example calculation */}
          <div className="bg-green-500/10 rounded-lg p-6 mb-8 border border-green-500/20">
            <p className="font-bold text-green-300 mb-4">📊 Exemple pour 400 appels/mois :</p>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between text-gray-300">
                <span>Abonnement mensuel</span>
                <span className="font-semibold">290€ HT</span>
              </div>
              <div className="flex justify-between text-gray-300">
                <span>~400 appels (3 min/appel en moyenne)</span>
                <span className="font-semibold">324€ HT</span>
              </div>
              <div className="flex justify-between text-gray-300">
                <span>~50 SMS de confirmation/rappel</span>
                <span className="font-semibold">7€ HT</span>
              </div>
              <div className="flex justify-between pt-2 mt-2 border-t border-green-500/20">
                <span className="font-bold text-white">Total</span>
                <span className="font-bold text-green-400">621€ HT/mois</span>
              </div>
              <div className="mt-4 pt-4 border-t border-green-500/10">
                <p className="text-xs text-gray-400 italic">
                  (Pour un poste de réceptionniste à temps plein : ~2500€ charges comprises)
                </p>
              </div>
            </div>
          </div>

          {/* CTA */}
          <div className="text-center">
            <Button size="lg" className="w-full md:w-auto bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700">
              Tester Alexandra gratuitement
            </Button>
            <p className="text-xs text-gray-400 mt-4">
              Alexandra s&apos;adapte à votre volume. Payez uniquement ce que vous consommez.
            </p>
          </div>
        </Card>

      </div>
    </section>
  );
}
