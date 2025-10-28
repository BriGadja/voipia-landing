'use client';

import { Card } from '@/components/shared/Card';
import { Upload, Zap, BarChart3 } from 'lucide-react';

const steps = [
  {
    number: 1,
    icon: Upload,
    title: 'Importez vos contacts',
    description: 'Uploadez votre liste de prospects ou connectez votre CRM en 1 clic. CSV, API, Zapier, Make... tous les formats sont supportés.',
    color: 'from-blue-500 to-cyan-500',
    bgGlow: 'bg-blue-500/20',
  },
  {
    number: 2,
    icon: Zap,
    title: 'Configurez votre agent IA',
    description: 'Personnalisez le script, la voix, les objectifs. Notre IA s\'adapte à votre ton et vos process en quelques minutes.',
    color: 'from-violet-500 to-purple-500',
    bgGlow: 'bg-violet-500/20',
  },
  {
    number: 3,
    icon: BarChart3,
    title: 'Analysez les résultats',
    description: 'Dashboard temps réel avec KPIs, transcriptions, enregistrements. Optimisez en continu grâce aux insights IA.',
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
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-violet-500/10 border border-violet-500/20 backdrop-blur-sm mb-6">
            <span className="text-sm font-semibold text-violet-300">
              Simple et rapide
            </span>
          </div>
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            <span className="text-white">Comment ça marche ?</span>
          </h2>
          <p className="text-xl text-gray-300">
            Déployez votre agent IA en moins de 10 minutes. Aucune compétence technique requise.
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
