'use client';

import { Card } from '@/components/shared/Card';
import { Bell, Phone, Target, Calendar } from 'lucide-react';

const steps = [
  {
    number: 1,
    icon: Bell,
    title: 'Détection instantanée des leads entrants',
    description: 'Dès qu\'un prospect remplit un formulaire, demande un devis ou laisse ses coordonnées, Louis est déclenché automatiquement. Chaque seconde compte : Louis garantit un temps de réponse record pour maximiser vos chances de conversion.',
    color: 'from-blue-500 to-cyan-500',
  },
  {
    number: 2,
    icon: Phone,
    title: 'Rappel automatique et conversation intelligente',
    description: 'Louis appelle le prospect dans la minute, en adaptant son discours à votre secteur. Il mène des conversations naturelles, pose les bonnes questions de qualification et peut même envoyer un SMS de pré-notification pour augmenter le taux de réponse.',
    color: 'from-cyan-500 to-blue-500',
  },
  {
    number: 3,
    icon: Target,
    title: 'Qualification intelligente et scoring automatique',
    description: 'Pendant la conversation, Louis qualifie chaque lead selon vos critères : budget, besoin, urgence, autorité. Il attribue automatiquement un score à chaque prospect (chaud, tiède, froid) et détermine s\'il est prêt pour un rendez-vous commercial.',
    color: 'from-blue-500 to-indigo-500',
  },
  {
    number: 4,
    icon: Calendar,
    title: 'Prise de rendez-vous et suivi continu',
    description: 'Pour les leads qualifiés, Louis consulte directement votre agenda et réserve un créneau disponible. Le rendez-vous est confirmé par SMS et email, synchronisé avec votre CRM, et Louis retente automatiquement les prospects non-joignables. Votre équipe reçoit un dossier complet avant chaque rendez-vous.',
    color: 'from-indigo-500 to-blue-500',
  },
];

export function HowItWorksLouis() {
  return (
    <section className="py-24 relative overflow-hidden">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-b from-blue-900/5 via-cyan-900/10 to-blue-900/5" />

      <div className="container mx-auto px-4 relative z-10">

        {/* Section header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6 text-white">
            Comment fonctionne Louis
          </h2>
        </div>

        {/* Steps */}
        <div className="max-w-5xl mx-auto space-y-12">
          {steps.map((step) => (
            <div key={step.number} className="relative flex flex-col md:flex-row gap-8 items-start">

              {/* Step number & icon */}
              <div className="relative flex-shrink-0">
                <div className={`w-20 h-20 rounded-2xl bg-gradient-to-br ${step.color} flex items-center justify-center shadow-lg`}>
                  <step.icon className="w-10 h-10 text-white" />
                </div>
                <div className="absolute -top-2 -right-2 w-8 h-8 rounded-full bg-gradient-to-br from-blue-600 to-cyan-600 flex items-center justify-center text-white font-bold text-sm border-4 border-gray-950">
                  {step.number}
                </div>
              </div>

              {/* Content */}
              <Card variant="gradient" className="flex-1 p-8">
                <h3 className="text-2xl font-bold text-white mb-4">
                  {step.title}
                </h3>
                <p className="text-gray-300 leading-relaxed">
                  {step.description}
                </p>
              </Card>

              {/* Connector line (not on last step) */}
              {step.number < steps.length && (
                <div className="absolute left-10 top-20 w-0.5 h-12 bg-gradient-to-b from-cyan-500/50 to-transparent md:block hidden" />
              )}
            </div>
          ))}
        </div>

        {/* Bottom visual callout */}
        <div className="mt-16 max-w-4xl mx-auto">
          <Card variant="gradient" className="p-8 text-center">
            <div className="flex flex-wrap items-center justify-center gap-4 text-gray-400 text-sm">
              <span className="text-2xl">📝</span>
              <span>Formulaire</span>
              <span className="text-blue-400">→</span>
              <span className="text-2xl">📞</span>
              <span>Louis</span>
              <span className="text-blue-400">→</span>
              <span className="text-2xl">☎️</span>
              <span>Appel</span>
              <span className="text-blue-400">→</span>
              <span className="text-2xl">✅</span>
              <span>Qualification</span>
              <span className="text-blue-400">→</span>
              <span className="text-2xl">📅</span>
              <span>RDV</span>
              <span className="text-blue-400">→</span>
              <span className="text-2xl">💼</span>
              <span>CRM</span>
            </div>
            <p className="text-gray-300 mt-4">
              Du formulaire au rendez-vous qualifié, Louis gère tout automatiquement.
            </p>
          </Card>
        </div>

      </div>
    </section>
  );
}
