'use client';

import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';
import { AudioPlayer } from '@/components/shared/AudioPlayer';
import { agents } from '@/lib/data/agents';
import { ArrowRight, TrendingUp } from 'lucide-react';
import Link from 'next/link';

const audioSamples = {
  louis: '/audio/louis-demo.mp3',
  arthur: '/audio/arthur-demo.mp3',
  alexandra: '/audio/alexandra-demo.mp3',
};

export function AgentsGridHome() {
  const agentsList = Object.values(agents);

  return (
    <section className="py-16 relative">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-purple-900/5 to-transparent" />

      <div className="container mx-auto px-4 relative z-10">

        {/* Section header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            <span className="bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent">
              Rencontrez votre nouvelle équipe commerciale
            </span>
          </h2>
          <p className="text-xl text-gray-300">
            Chaque agent est spécialisé dans un cas d&apos;usage précis pour maximiser vos conversions.
          </p>
        </div>

        {/* Agents grid */}
        <div className="grid md:grid-cols-3 gap-8 max-w-7xl mx-auto">
          {agentsList.map((agent) => {
            const audioSrc = audioSamples[agent.id as keyof typeof audioSamples];

            return (
              <Card
                key={agent.id}
                variant="gradient"
                className="p-8 flex flex-col gap-6 hover:scale-105 transition-transform duration-300 h-full"
              >
                {/* Header */}
                <div className="flex-1">
                  <div className="text-4xl mb-4">{agent.icon}</div>
                  <h3 className={`text-2xl font-bold mb-3 bg-gradient-to-r ${agent.color.gradient} bg-clip-text text-transparent`}>
                    {agent.displayName}
                  </h3>
                  <p className="text-gray-300 text-sm leading-relaxed">
                    {agent.description}
                  </p>
                </div>

                {/* Audio player */}
                <div className="bg-black/20 rounded-lg p-4 border border-white/5">
                  <p className="text-xs text-gray-400 mb-3 flex items-center gap-2">
                    <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                    Écoutez {agent.displayName} en action
                  </p>
                  <AudioPlayer
                    src={audioSrc}
                    variant={agent.id as 'louis' | 'arthur' | 'alexandra'}
                  />
                </div>

                {/* CTA */}
                <Button
                  variant="outline"
                  size="md"
                  className={`w-full group border-2 hover:bg-gradient-to-r ${agent.color.gradient} hover:border-transparent`}
                  asChild
                >
                  <Link href={`/${agent.id}`}>
                    Découvrir {agent.displayName}
                  </Link>
                </Button>
              </Card>
            );
          })}
        </div>

        {/* Bottom CTA */}
        <div className="text-center mt-16">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-green-500/10 border border-green-500/20 backdrop-blur-sm">
            <TrendingUp className="w-4 h-4 text-green-400" />
            <span className="text-sm font-medium text-green-300">
              Combine plusieurs agents pour des résultats encore meilleurs
            </span>
          </div>
        </div>

      </div>
    </section>
  );
}
