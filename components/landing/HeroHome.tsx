'use client';

import { Button } from '@/components/shared/Button';
import { agents } from '@/lib/data/agents';
import { ArrowRight, CheckCircle2 } from 'lucide-react';
import Link from 'next/link';

export function HeroHome() {
  const agentsList = Object.values(agents);

  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Background gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-violet-900/20 via-purple-900/10 to-transparent" />

      {/* Grid pattern overlay */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#ffffff08_1px,transparent_1px),linear-gradient(to_bottom,#ffffff08_1px,transparent_1px)] bg-[size:4rem_4rem]" />

      <div className="container mx-auto px-4 py-20 relative z-10">
        <div className="max-w-5xl mx-auto text-center space-y-8">

          {/* Badge */}
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-violet-500/10 border border-violet-500/20 backdrop-blur-sm">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-violet-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-violet-500"></span>
            </span>
            <span className="text-sm font-medium text-violet-300">
              Intelligence Artificielle Vocale 2025
            </span>
          </div>

          {/* Main heading */}
          <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold leading-tight">
            <span className="bg-gradient-to-r from-violet-400 via-purple-400 to-pink-400 bg-clip-text text-transparent">
              Déléguez le traitement{' '}
            </span>
            <br />
            <span className="text-white">
              de vos prospects à nos agents IA
            </span>
          </h1>

          {/* Subtitle */}
          <p className="text-xl md:text-2xl text-gray-300 max-w-3xl mx-auto leading-relaxed">
            Louis rappelle chaque nouveau lead. Alexandra répond à chaque appel.
            Arthur relance chaque prospect dormant.<br />
            <span className="text-violet-300 font-semibold">→ Résultat : votre agenda se remplit de RDV qualifiés, tous vos prospects sont traités</span>
          </p>

          {/* Agents list */}
          <div className="flex flex-wrap justify-center gap-4 py-4">
            {agentsList.map((agent) => (
              <div
                key={agent.id}
                className="flex items-center gap-2 px-4 py-2 rounded-lg bg-white/5 border border-white/10 backdrop-blur-sm"
              >
                <span className="text-2xl">{agent.icon}</span>
                <div className="text-left">
                  <p className={`font-semibold text-sm bg-gradient-to-r ${agent.color.gradient} bg-clip-text text-transparent`}>
                    {agent.displayName}
                  </p>
                  <p className="text-xs text-gray-400">{agent.tagline}</p>
                </div>
                <CheckCircle2 className="w-4 h-4 text-green-400 ml-1" />
              </div>
            ))}
          </div>

          {/* CTAs */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center pt-4">
            <Button size="lg" className="group">
              Tester nos agents gratuitement
              <ArrowRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" />
            </Button>
            <Button size="lg" variant="secondary" asChild>
              <Link href="#demo">
                Écouter un exemple d'appel
              </Link>
            </Button>
          </div>

          {/* Social proof */}
          <div className="flex flex-wrap justify-center items-center gap-8 pt-8 text-sm text-gray-400">
            <div className="flex items-center gap-2">
              <div className="flex -space-x-2">
                {[1, 2, 3, 4].map((i) => (
                  <div
                    key={i}
                    className="w-8 h-8 rounded-full bg-gradient-to-br from-violet-500 to-purple-500 border-2 border-gray-900"
                  />
                ))}
              </div>
              <span>+50 entreprises conquises</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-yellow-400">★★★★★</span>
              <span>4.9/5 satisfaction client</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-green-400 font-bold">+72%</span>
              <span>de taux de contact moyen</span>
            </div>
          </div>

        </div>
      </div>

      {/* Bottom fade */}
      <div className="absolute bottom-0 inset-x-0 h-32 bg-gradient-to-t from-gray-950 to-transparent" />
    </section>
  );
}
