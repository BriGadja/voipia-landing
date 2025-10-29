import Link from 'next/link';
import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';
import { Sparkles, ArrowRight } from 'lucide-react';
import { getOtherAgents } from '@/lib/data/agents';

interface OtherAgentsProps {
  currentAgent: 'louis' | 'arthur' | 'alexandra';
}

export function OtherAgents({ currentAgent }: OtherAgentsProps) {
  const otherAgents = getOtherAgents(currentAgent);

  return (
    <section className="py-24 relative overflow-hidden">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-b from-black via-violet-950/20 to-black" />
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(139,92,246,0.1),transparent_50%)]" />

      <div className="container mx-auto px-4 relative z-10">
        {/* Header */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-violet-500/10 border border-violet-500/20 backdrop-blur-sm mb-6">
            <Sparkles className="w-4 h-4 text-violet-400" />
            <span className="text-sm font-semibold text-violet-300">
              Découvrez nos autres solutions
            </span>
          </div>
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            <span className="text-white">Vous avez d&apos;autres défis ?</span>
            <br />
            <span className="bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent">
              Découvrez nos autres agents IA
            </span>
          </h2>
          <p className="text-xl text-gray-300">
            Maximisez votre efficacité commerciale avec une équipe complète d&apos;agents IA spécialisés.
          </p>
        </div>

        {/* Agents Grid */}
        <div className="grid md:grid-cols-2 gap-8 max-w-5xl mx-auto mb-12">
          {otherAgents.map((agent) => (
            <Link key={agent.id} href={`/${agent.id}`}>
              <Card variant="hover" className="p-8 h-full group">
                {/* Badge */}
                <div className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-sm font-medium mb-6 bg-gradient-to-r ${agent.color.gradient} bg-opacity-10`}>
                  <span className="text-2xl">{agent.icon}</span>
                  <span className="text-white">{agent.tagline}</span>
                </div>

                {/* Content */}
                <h3 className="text-2xl font-bold text-white mb-4 group-hover:text-violet-400 transition-colors">
                  {agent.displayName}
                </h3>
                <p className="text-gray-400 mb-6 leading-relaxed">
                  {agent.description}
                </p>

                {/* CTA */}
                <div className="flex items-center gap-2 text-violet-400 font-semibold group-hover:gap-4 transition-all">
                  <span>En savoir plus</span>
                  <ArrowRight className="w-5 h-5" />
                </div>
              </Card>
            </Link>
          ))}
        </div>

        {/* Bundle CTA */}
        <div className="max-w-3xl mx-auto">
          <Card variant="gradient" className="p-8 text-center bg-gradient-to-r from-violet-600/20 via-purple-600/20 to-pink-600/20 border-violet-500/30">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-green-500/20 text-green-400 font-semibold mb-6">
              💰 Économisez 8% avec le Pack Complet
            </div>
            <h3 className="text-3xl font-bold text-white mb-4">
              Combinez les 3 agents pour une couverture totale
            </h3>
            <p className="text-lg text-gray-300 mb-8">
              Offre Bundle : <span className="line-through text-gray-500">970€</span> <span className="text-3xl font-bold text-white">890€</span> HT/mois
            </p>
            <Button variant="primary" size="lg">
              Découvrir le Pack Complet →
            </Button>
          </Card>
        </div>
      </div>
    </section>
  );
}
