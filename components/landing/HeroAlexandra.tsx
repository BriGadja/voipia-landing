'use client';

import { Button } from '@/components/shared/Button';
import { agents } from '@/lib/data/agents';
import { Phone, Play } from 'lucide-react';

export function HeroAlexandra() {
  const alexandra = agents.alexandra;

  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Background gradient avec vert Alexandra */}
      <div className="absolute inset-0 bg-gradient-to-br from-green-900/20 via-emerald-900/10 to-transparent" />

      {/* Grid pattern */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#ffffff08_1px,transparent_1px),linear-gradient(to_bottom,#ffffff08_1px,transparent_1px)] bg-[size:4rem_4rem]" />

      <div className="container mx-auto px-4 py-20 relative z-10">
        <div className="max-w-5xl mx-auto text-center space-y-8">

          {/* Badge avec Alexandra icon */}
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-green-500/10 border border-green-500/20 backdrop-blur-sm">
            <span className="text-2xl">{alexandra.icon}</span>
            <span className="text-sm font-semibold text-green-300">
              {alexandra.badge}
            </span>
          </div>

          {/* Titre principal */}
          <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold leading-tight">
            <span className="bg-gradient-to-r from-green-400 via-emerald-400 to-green-400 bg-clip-text text-transparent">
              Rencontrez Alexandra.
            </span>
          </h1>

          {/* Sous-titre */}
          <p className="text-2xl md:text-3xl text-white max-w-4xl mx-auto leading-relaxed">
            Votre agent de réception IA qui répond, filtre et oriente chaque appel entrant automatiquement.
          </p>

          {/* Description punch */}
          <div className="space-y-4 max-w-3xl mx-auto">
            <p className="text-lg text-gray-300">
              Alexandra décroche chaque appel en moins de 3 sonneries, 24h/24 et 7j/7, dans plusieurs langues.
            </p>
            <p className="text-lg text-gray-300">
              Elle répond aux questions, filtre les demandes, prend des rendez-vous et transfère les appels pendant que votre équipe se concentre sur son cœur de métier.
            </p>
          </div>

          {/* CTAs */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center pt-6">
            <Button size="lg" className="group bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700">
              <Phone className="w-5 h-5 mr-2" />
              Tester gratuitement Alexandra
            </Button>
            <Button size="lg" variant="secondary">
              <Play className="w-5 h-5 mr-2" />
              Écouter un appel d&apos;Alexandra
            </Button>
          </div>

          {/* Stats rapides */}
          <div className="flex flex-wrap justify-center items-center gap-8 pt-12 text-sm">
            <div>
              <p className="text-2xl font-bold text-green-400">&lt; 3 sonneries</p>
              <p className="text-gray-400">Temps de réponse</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-green-400">100%</p>
              <p className="text-gray-400">Taux de réponse</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-green-400">24/7</p>
              <p className="text-gray-400">Disponibilité</p>
            </div>
          </div>

        </div>
      </div>
    </section>
  );
}
