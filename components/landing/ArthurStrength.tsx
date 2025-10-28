'use client';

import { Card } from '@/components/shared/Card';
import { Heart, Zap, Brain, ArrowRight } from 'lucide-react';

export function ArthurStrength() {
  return (
    <section className="py-24 relative">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-orange-900/5 to-transparent" />

      <div className="container mx-auto px-4 relative z-10">
        {/* Section header */}
        <div className="text-center max-w-4xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            <span className="bg-gradient-to-r from-orange-400 to-amber-400 bg-clip-text text-transparent">
              Arthur, l&apos;agent IA
            </span>
            <br />
            <span className="text-white">
              qui relance tout et ne s&apos;essouffle jamais
            </span>
          </h2>
          <p className="text-xl text-gray-300">
            Là où votre équipe s&apos;arrête, Arthur continue.
          </p>
        </div>

        {/* 3 blocks grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-7xl mx-auto">
          {/* Block 1: Approche douce */}
          <Card variant="gradient" className="p-8">
            <div className="w-12 h-12 rounded-full bg-orange-500/10 flex items-center justify-center mb-6">
              <Heart className="w-6 h-6 text-orange-400" />
            </div>
            <h3 className="text-xl font-bold text-white mb-4">
              💙 Une approche douce qui respecte vos prospects
            </h3>
            <p className="text-gray-300 leading-relaxed">
              Arthur ne bombarde pas vos contacts. Il déploie une stratégie de relance progressive et naturelle qui s&apos;adapte à la réaction de chaque prospect. Son objectif : réactiver sans agacer. Ses relances sont personnalisées, espacées intelligemment et toujours professionnelles.
            </p>
          </Card>

          {/* Block 2: Capacité massive */}
          <Card variant="gradient" className="p-8">
            <div className="w-12 h-12 rounded-full bg-orange-500/10 flex items-center justify-center mb-6">
              <Zap className="w-6 h-6 text-orange-400" />
            </div>
            <h3 className="text-xl font-bold text-white mb-4">
              ⚡ Capacité de traiter des milliers de contacts par mois
            </h3>
            <p className="text-gray-300 leading-relaxed mb-4">
              Arthur peut gérer simultanément des campagnes de réactivation massives :
            </p>
            <ul className="space-y-2 text-gray-300 text-sm">
              <li className="flex items-start gap-2">
                <span className="text-orange-400 mt-1">✓</span>
                <span>Bases de 1 000 à 50 000 contacts</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-orange-400 mt-1">✓</span>
                <span>Campagnes parallèles sur plusieurs segments</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-orange-400 mt-1">✓</span>
                <span>Traitement de 500+ leads par semaine</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-orange-400 mt-1">✓</span>
                <span>Aucune limite de volume</span>
              </li>
            </ul>
          </Card>

          {/* Block 3: Intelligence adaptative */}
          <Card variant="gradient" className="p-8">
            <div className="w-12 h-12 rounded-full bg-orange-500/10 flex items-center justify-center mb-6">
              <Brain className="w-6 h-6 text-orange-400" />
            </div>
            <h3 className="text-xl font-bold text-white mb-4">
              🧠 IA qui adapte sa relance selon la réaction du lead
            </h3>
            <p className="text-gray-300 leading-relaxed mb-4">
              Arthur analyse en temps réel le comportement de chaque lead et adapte sa stratégie :
            </p>
            <div className="space-y-3 text-sm">
              <div className="flex items-center gap-2 p-3 rounded-lg bg-orange-500/5 border border-orange-500/10">
                <span className="text-green-400">✓</span>
                <span className="text-gray-300">Lead réactif</span>
                <ArrowRight className="w-4 h-4 text-orange-400 ml-auto" />
                <span className="text-orange-300">Accélération vers le RDV</span>
              </div>
              <div className="flex items-center gap-2 p-3 rounded-lg bg-orange-500/5 border border-orange-500/10">
                <span className="text-yellow-400">~</span>
                <span className="text-gray-300">Lead hésitant</span>
                <ArrowRight className="w-4 h-4 text-orange-400 ml-auto" />
                <span className="text-orange-300">Relance douce</span>
              </div>
              <div className="flex items-center gap-2 p-3 rounded-lg bg-orange-500/5 border border-orange-500/10">
                <span className="text-gray-400">○</span>
                <span className="text-gray-300">Pas de réponse</span>
                <ArrowRight className="w-4 h-4 text-orange-400 ml-auto" />
                <span className="text-orange-300">Pause temporaire</span>
              </div>
            </div>
          </Card>
        </div>

        {/* Baseline */}
        <div className="text-center mt-12">
          <p className="text-lg text-gray-300 max-w-4xl mx-auto">
            Arthur n&apos;est pas un simple agent IA. C&apos;est votre allié commercial qui ramène du business dormant pendant que vos équipes se concentrent sur la vente.
          </p>
        </div>
      </div>
    </section>
  );
}
