'use client';

import { Button } from '@/components/shared/Button';
import { agents } from '@/lib/data/agents';
import { Phone, Play } from 'lucide-react';

export function HeroArthur() {
  const arthur = agents.arthur;

  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Background gradient avec orange Arthur */}
      <div className="absolute inset-0 bg-gradient-to-br from-orange-900/20 via-amber-900/10 to-transparent" />

      {/* Grid pattern */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#ffffff08_1px,transparent_1px),linear-gradient(to_bottom,#ffffff08_1px,transparent_1px)] bg-[size:4rem_4rem]" />

      <div className="container mx-auto px-4 py-20 relative z-10">
        <div className="max-w-5xl mx-auto text-center space-y-8">

          {/* Badge avec Arthur icon */}
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-orange-500/10 border border-orange-500/20 backdrop-blur-sm">
            <span className="text-2xl">{arthur.icon}</span>
            <span className="text-sm font-semibold text-orange-300">
              {arthur.badge}
            </span>
          </div>

          {/* Titre principal */}
          <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold leading-tight">
            <span className="bg-gradient-to-r from-orange-400 via-amber-400 to-orange-400 bg-clip-text text-transparent">
              Rencontrez Arthur.
            </span>
          </h1>

          {/* Sous-titre */}
          <p className="text-2xl md:text-3xl text-white max-w-4xl mx-auto leading-relaxed">
            Votre agent de réactivation IA qui redonne vie à vos prospects oubliés pour ne laisser passer aucune opportunité.
          </p>

          {/* Description punch */}
          <div className="space-y-4 max-w-3xl mx-auto">
            <p className="text-lg text-gray-300">
              Arthur relance automatiquement vos contacts dormants avec une approche douce et personnalisée, 24h/24 et 7j/7.
            </p>
            <p className="text-lg text-gray-300">
              Il réactive vos opportunités oubliées et planifie des rendez-vous – pendant que vos commerciaux se concentrent sur les leads chauds.
            </p>
          </div>

          {/* CTAs */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center pt-6">
            <Button size="lg" className="group bg-gradient-to-r from-orange-600 to-amber-600 hover:from-orange-700 hover:to-amber-700">
              <Phone className="w-5 h-5 mr-2" />
              Tester gratuitement Arthur
            </Button>
            <Button size="lg" variant="secondary">
              <Play className="w-5 h-5 mr-2" />
              Écouter un appel d&apos;Arthur
            </Button>
          </div>

        </div>
      </div>

      {/* Bottom fade */}
      <div className="absolute bottom-0 inset-x-0 h-32 bg-gradient-to-t from-gray-950 to-transparent" />
    </section>
  );
}
