'use client';

import { Button } from '@/components/shared/Button';
import { agents } from '@/lib/data/agents';
import { Phone, Play } from 'lucide-react';

export function HeroLouis() {
  const louis = agents.louis;

  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Background gradient avec bleu Louis */}
      <div className="absolute inset-0 bg-gradient-to-br from-blue-900/20 via-cyan-900/10 to-transparent" />

      {/* Grid pattern */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#ffffff08_1px,transparent_1px),linear-gradient(to_bottom,#ffffff08_1px,transparent_1px)] bg-[size:4rem_4rem]" />

      <div className="container mx-auto px-4 py-20 relative z-10">
        <div className="max-w-5xl mx-auto text-center space-y-8">

          {/* Badge avec Louis icon */}
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-blue-500/10 border border-blue-500/20 backdrop-blur-sm">
            <span className="text-2xl">{louis.icon}</span>
            <span className="text-sm font-semibold text-blue-300">
              {louis.badge}
            </span>
          </div>

          {/* Titre principal */}
          <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold leading-tight">
            <span className="bg-gradient-to-r from-blue-400 via-cyan-400 to-blue-400 bg-clip-text text-transparent">
              Rencontrez Louis.
            </span>
          </h1>

          {/* Sous-titre */}
          <p className="text-2xl md:text-3xl text-white max-w-4xl mx-auto leading-relaxed">
            Votre agent IA personnel, qui rappelle, qualifie et planifie chaque nouveau lead automatiquement.
          </p>

          {/* Description punch */}
          <div className="space-y-4 max-w-3xl mx-auto">
            <p className="text-lg text-gray-300">
              Louis contacte vos prospects en moins d&apos;une minute, 24h/24 et 7j/7, dans plus de 20 langues.
            </p>
            <p className="text-lg text-gray-300">
              Il échange, qualifie et planifie vos rendez-vous automatiquement – pendant que votre équipe se concentre sur la vente.
            </p>
          </div>

          {/* CTAs */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center pt-6">
            <Button size="lg" className="group bg-gradient-to-r from-blue-600 to-cyan-600 hover:from-blue-700 hover:to-cyan-700">
              <Phone className="w-5 h-5 mr-2" />
              Tester Louis gratuitement
            </Button>
            <Button size="lg" variant="secondary">
              <Play className="w-5 h-5 mr-2" />
              Écouter un appel de Louis
            </Button>
          </div>

          {/* Stats rapides */}
          <div className="flex flex-wrap justify-center items-center gap-8 pt-12 text-sm">
            <div>
              <p className="text-2xl font-bold text-blue-400">&lt; 60s</p>
              <p className="text-gray-400">Délai de rappel</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-blue-400">+72%</p>
              <p className="text-gray-400">Taux de contact</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-blue-400">x3</p>
              <p className="text-gray-400">RDV qualifiés</p>
            </div>
          </div>

        </div>
      </div>

      {/* Bottom fade */}
      <div className="absolute bottom-0 inset-x-0 h-32 bg-gradient-to-t from-gray-950 to-transparent" />
    </section>
  );
}
