'use client';

import { Card } from '@/components/shared/Card';
import { Plug, Target, CalendarCheck } from 'lucide-react';

const steps = [
  {
    number: 1,
    icon: Plug,
    title: 'Connexion instantanée',
    description: 'Connectez VoIPIA à votre CRM, votre agenda et vos sources de leads en quelques clics. Aucun développement nécessaire.',
    color: 'from-blue-500 to-cyan-500',
    bgGlow: 'bg-blue-500/20',
  },
  {
    number: 2,
    icon: Target,
    title: 'Qualification automatique',
    description: 'Nos agents traitent chaque prospect selon vos critères : budget, besoin, urgence. Seuls les leads qualifiés arrivent à votre équipe.',
    color: 'from-violet-500 to-purple-500',
    bgGlow: 'bg-violet-500/20',
  },
  {
    number: 3,
    icon: CalendarCheck,
    title: 'Agenda rempli',
    description: 'Les RDV sont planifiés directement dans votre agenda. SMS et emails de confirmation automatiques. Vous arrivez préparé.',
    color: 'from-green-500 to-emerald-500',
    bgGlow: 'bg-green-500/20',
  },
];

export function HowItWorksHome() {
  return (
    <section className="py-24 relative overflow-hidden">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-violet-900/10 via-transparent to-transparent" />

      <div className="container mx-auto px-4 relative z-10">

        {/* Section header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            <span className="text-white">Découvrez comment nos agents s&apos;occupent de vos opportunités</span>
          </h2>
          <p className="text-xl text-gray-300">
            De la génération de leads à la prise de rendez-vous, VoIPIA s&apos;intègre parfaitement dans votre workflow.
          </p>
        </div>

        {/* Steps */}
        <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {steps.map((step, idx) => (
            <div key={step.number} className="relative">
              {/* Connector line (desktop only) */}
              {idx < steps.length - 1 && (
                <div className="hidden md:block absolute top-16 left-[60%] w-[80%] h-0.5 bg-gradient-to-r from-white/20 to-transparent z-0" />
              )}

              <Card variant="gradient" className="p-8 relative z-10 h-full">
                {/* Icon */}
                <div className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${step.color} flex items-center justify-center mb-6 relative`}>
                  <div className={`absolute inset-0 rounded-2xl ${step.bgGlow} blur-xl`} />
                  <step.icon className="w-8 h-8 text-white relative z-10" />
                </div>

                {/* Step number */}
                <div className="inline-flex items-center justify-center w-8 h-8 rounded-full bg-white/10 border border-white/20 text-sm font-bold text-white mb-4">
                  {step.number}
                </div>

                {/* Content */}
                <h3 className={`text-xl font-bold mb-3 bg-gradient-to-r ${step.color} bg-clip-text text-transparent`}>
                  {step.title}
                </h3>
                <p className="text-gray-300 text-sm leading-relaxed">
                  {step.description}
                </p>
              </Card>
            </div>
          ))}
        </div>

        {/* Bottom note */}
        <div className="text-center mt-12">
          <p className="text-sm text-gray-400">
            Besoin d&apos;aide pour démarrer ?{' '}
            <span className="text-violet-400 font-semibold cursor-pointer hover:underline">
              Notre équipe vous accompagne gratuitement
            </span>
          </p>
        </div>

      </div>
    </section>
  );
}
