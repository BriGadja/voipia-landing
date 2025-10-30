'use client';

import { Button } from '@/components/shared/Button';
import { agents } from '@/lib/data/agents';
import { ArrowRight, CheckCircle2 } from 'lucide-react';
import Link from 'next/link';
import { RippleBackground } from '@/components/animations/RippleBackground';

export function HeroHome() {
  const agentsList = Object.values(agents);

  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Animated ripple background */}
      <RippleBackground />

      <div className="container mx-auto px-4 py-20 relative z-10">
        <div className="max-w-5xl mx-auto text-center space-y-8">

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

          {/* CTA */}
          <div className="flex justify-center items-center pt-4">
            <Button size="lg">
              TESTER NOS AGENTS
            </Button>
          </div>

        </div>
      </div>

      {/* Bottom fade */}
      <div className="absolute bottom-0 inset-x-0 h-32 bg-gradient-to-t from-gray-950 to-transparent" />
    </section>
  );
}
