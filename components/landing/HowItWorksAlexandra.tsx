'use client';

import { Card } from '@/components/shared/Card';
import { Phone, MessageCircle, Filter, Calendar } from 'lucide-react';

const steps = [
  {
    number: 1,
    icon: Phone,
    title: 'Réception instantanée de tous les appels entrants',
    description: 'Dès qu\'un appel arrive sur votre ligne, Alexandra décroche automatiquement en moins de 3 sonneries. Fini les appels manqués, les répondeurs impersonnels ou les clients perdus par manque de disponibilité. Alexandra garantit que 100% de vos appels sont traités.',
    color: 'from-green-500 to-emerald-500',
  },
  {
    number: 2,
    icon: MessageCircle,
    title: 'Réponse personnalisée grâce à votre base de connaissances',
    description: 'Alexandra connaît parfaitement votre entreprise grâce à la base de connaissances que vous lui avez fournie (produits, services, tarifs, horaires, FAQ). Elle répond aux questions de vos clients et prospects de manière naturelle et pertinente, comme le ferait votre meilleure réceptionniste.',
    color: 'from-emerald-500 to-green-500',
  },
  {
    number: 3,
    icon: Filter,
    title: 'Filtrage intelligent et qualification automatique',
    description: 'Alexandra qualifie chaque appelant selon vos critères : urgence, type de demande, statut client. Elle identifie les appels prioritaires (clients VIP, urgences) et filtre les sollicitations indésirables (démarchage, spam). Chaque appel reçoit un score et une catégorisation automatique.',
    color: 'from-green-500 to-teal-500',
  },
  {
    number: 4,
    icon: Calendar,
    title: 'Prise de rendez-vous, transfert et suivi continu',
    description: 'Selon la demande, Alexandra peut prendre un rendez-vous directement dans votre agenda, transférer l\'appel vers le bon interlocuteur, ou enregistrer un message détaillé. Toutes les informations sont synchronisées avec votre CRM, et un compte-rendu complet est envoyé par email après chaque appel.',
    color: 'from-teal-500 to-green-500',
  },
];

export function HowItWorksAlexandra() {
  return (
    <section className="py-24 relative overflow-hidden">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-b from-green-900/5 via-emerald-900/10 to-green-900/5" />

      <div className="container mx-auto px-4 relative z-10">

        {/* Section header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6 text-white">
            Comment fonctionne Alexandra
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
                <div className="absolute -top-2 -right-2 w-8 h-8 rounded-full bg-gradient-to-br from-green-600 to-emerald-600 flex items-center justify-center text-white font-bold text-sm border-4 border-gray-950">
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
                <div className="absolute left-10 top-20 w-0.5 h-12 bg-gradient-to-b from-emerald-500/50 to-transparent md:block hidden" />
              )}
            </div>
          ))}
        </div>

        {/* Bottom visual callout */}
        <div className="mt-16 max-w-4xl mx-auto">
          <Card variant="gradient" className="p-8 text-center">
            <div className="flex flex-wrap items-center justify-center gap-4 text-gray-400 text-sm">
              <span className="text-2xl">📞</span>
              <span>Appel entrant</span>
              <span className="text-green-400">→</span>
              <span className="text-2xl">☎️</span>
              <span>Alexandra</span>
              <span className="text-green-400">→</span>
              <span className="text-2xl">💬</span>
              <span>Conversation</span>
              <span className="text-green-400">→</span>
              <span className="text-2xl">✅</span>
              <span>Qualification</span>
              <span className="text-green-400">→</span>
              <span className="text-2xl">📅</span>
              <span>RDV / Transfert</span>
              <span className="text-green-400">→</span>
              <span className="text-2xl">💼</span>
              <span>CRM</span>
            </div>
            <p className="text-gray-300 mt-4">
              De la réception à l&apos;action, Alexandra gère tout automatiquement.
            </p>
          </Card>
        </div>

      </div>
    </section>
  );
}
