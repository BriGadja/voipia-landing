'use client';

import { Card } from '@/components/shared/Card';
import { Database, Phone, Target, Calendar, ArrowRight } from 'lucide-react';

const steps = [
  {
    number: '01',
    icon: Database,
    title: 'Détection automatique des opportunités oubliées',
    description:
      "Arthur analyse votre CRM et vos bases de données pour identifier tous les leads dormants : prospects jamais rappelés, contacts sans réponse (NRP), opportunités en attente, anciens leads froids. Il segmente automatiquement votre base selon l'historique et le potentiel de réactivation.",
  },
  {
    number: '02',
    icon: Phone,
    title: 'Relances naturelles et multicanales',
    description:
      "Arthur déploie des relances progressives et multicanales – appels, SMS et emails – selon la réaction de chaque prospect. Son approche est douce, personnalisée et non intrusive pour ne pas agacer vos contacts. Chaque relance est adaptée en temps réel au comportement du lead.",
  },
  {
    number: '03',
    icon: Target,
    title: 'Priorisation automatique des leads prometteurs',
    description:
      "À chaque interaction, Arthur qualifie le niveau d'intérêt du lead et attribue un score automatique. Il classe les leads selon leur niveau d'intérêt pour que vos commerciaux se concentrent uniquement sur les plus prometteurs. Seules les vraies opportunités arrivent jusqu'à votre équipe.",
  },
  {
    number: '04',
    icon: Calendar,
    title: 'Conversion et libération de temps pour vos équipes',
    description:
      "Pour les leads réactivés, Arthur consulte directement votre agenda et réserve un créneau disponible. Le rendez-vous est confirmé par SMS et email, synchronisé avec votre CRM. Vos équipes ne perdent plus de temps à rappeler manuellement – elles ne traitent que les prospects déjà réchauffés par Arthur.",
  },
];

export function HowItWorksArthur() {
  return (
    <section className="py-24 relative">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-orange-900/5 to-transparent" />

      <div className="container mx-auto px-4 relative z-10">
        {/* Section header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            <span className="text-white">Comment fonctionne</span>
            <br />
            <span className="bg-gradient-to-r from-orange-400 to-amber-400 bg-clip-text text-transparent">
              Arthur
            </span>
          </h2>
        </div>

        {/* Steps grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-6xl mx-auto mb-16">
          {steps.map((step, index) => {
            const Icon = step.icon;
            return (
              <Card key={index} variant="gradient" className="p-8">
                {/* Step number */}
                <div className="flex items-start gap-4 mb-4">
                  <div className="flex-shrink-0">
                    <div className="w-12 h-12 rounded-full bg-gradient-to-br from-orange-500 to-amber-500 flex items-center justify-center">
                      <span className="text-white font-bold text-lg">
                        {step.number}
                      </span>
                    </div>
                  </div>
                  <div className="flex-shrink-0 mt-1">
                    <div className="w-10 h-10 rounded-lg bg-orange-500/10 flex items-center justify-center">
                      <Icon className="w-5 h-5 text-orange-400" />
                    </div>
                  </div>
                </div>

                {/* Content */}
                <h3 className="text-xl font-bold text-white mb-3">
                  {step.title}
                </h3>
                <p className="text-gray-300 leading-relaxed">
                  {step.description}
                </p>
              </Card>
            );
          })}
        </div>

        {/* Visual flow */}
        <div className="max-w-5xl mx-auto">
          <Card variant="gradient" className="p-8">
            <p className="text-center text-gray-300 mb-6 font-semibold">
              Arthur réactive vos opportunités avec une approche douce et progressive.
            </p>
            <div className="flex flex-wrap items-center justify-center gap-3 text-sm">
              <div className="flex items-center gap-2 px-4 py-2 rounded-lg bg-orange-500/10 border border-orange-500/20">
                <Database className="w-4 h-4 text-orange-400" />
                <span className="text-gray-200">Base dormante</span>
              </div>
              <ArrowRight className="w-4 h-4 text-orange-400" />
              <div className="flex items-center gap-2 px-4 py-2 rounded-lg bg-orange-500/10 border border-orange-500/20">
                <Phone className="w-4 h-4 text-orange-400" />
                <span className="text-gray-200">Appel</span>
              </div>
              <ArrowRight className="w-4 h-4 text-orange-400" />
              <div className="flex items-center gap-2 px-4 py-2 rounded-lg bg-orange-500/10 border border-orange-500/20">
                <span className="text-orange-400">💬</span>
                <span className="text-gray-200">SMS</span>
              </div>
              <ArrowRight className="w-4 h-4 text-orange-400" />
              <div className="flex items-center gap-2 px-4 py-2 rounded-lg bg-orange-500/10 border border-orange-500/20">
                <span className="text-orange-400">📧</span>
                <span className="text-gray-200">Email</span>
              </div>
              <ArrowRight className="w-4 h-4 text-orange-400" />
              <div className="flex items-center gap-2 px-4 py-2 rounded-lg bg-orange-500/10 border border-orange-500/20">
                <span className="text-orange-400">🔄</span>
                <span className="text-gray-200">Relance progressive</span>
              </div>
              <ArrowRight className="w-4 h-4 text-orange-400" />
              <div className="flex items-center gap-2 px-4 py-2 rounded-lg bg-orange-500/10 border border-orange-500/20">
                <Calendar className="w-4 h-4 text-orange-400" />
                <span className="text-gray-200">RDV qualifié</span>
              </div>
              <ArrowRight className="w-4 h-4 text-orange-400" />
              <div className="flex items-center gap-2 px-4 py-2 rounded-lg bg-orange-500/10 border border-orange-500/20">
                <span className="text-orange-400">📊</span>
                <span className="text-gray-200">CRM</span>
              </div>
            </div>
          </Card>
        </div>
      </div>
    </section>
  );
}
