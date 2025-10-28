'use client';

import { Button } from '@/components/shared/Button';
import { Card } from '@/components/shared/Card';
import { Phone, Play } from 'lucide-react';

export function CTAFinalArthur() {
  return (
    <section className="py-24 relative overflow-hidden">
      {/* Background gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-orange-900/30 via-amber-900/20 to-transparent" />

      {/* Grid pattern */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#ffffff08_1px,transparent_1px),linear-gradient(to_bottom,#ffffff08_1px,transparent_1px)] bg-[size:4rem_4rem]" />

      <div className="container mx-auto px-4 relative z-10">
        <Card variant="gradient" className="max-w-5xl mx-auto p-12 md:p-16 text-center">

          {/* Main title */}
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-6">
            <span className="bg-gradient-to-r from-orange-400 to-amber-400 bg-clip-text text-transparent">
              Redonnez vie à vos opportunités oubliées
            </span>
            <br />
            <span className="text-white">
              dès aujourd&apos;hui
            </span>
          </h2>

          {/* Subtitle */}
          <p className="text-xl md:text-2xl text-gray-300 mb-10 max-w-3xl mx-auto leading-relaxed">
            Testez gratuitement Arthur et découvrez combien de CA dort dans votre base de données en moins d&apos;une semaine.
          </p>

          {/* CTAs */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <Button
              size="lg"
              className="group bg-gradient-to-r from-orange-600 to-amber-600 hover:from-orange-700 hover:to-amber-700"
            >
              <Phone className="w-5 h-5 mr-2" />
              Tester gratuitement Arthur
            </Button>
            <Button size="lg" variant="secondary">
              <Play className="w-5 h-5 mr-2" />
              Écouter un appel de réactivation d&apos;Arthur
            </Button>
          </div>

          {/* Social proof */}
          <div className="mt-12 pt-8 border-t border-white/10">
            <p className="text-sm text-gray-400 mb-3">
              Rejoignez les entreprises qui transforment leurs bases dormantes en opportunités
            </p>
            <div className="flex flex-wrap justify-center items-center gap-6 text-sm text-gray-500">
              <div className="flex items-center gap-2">
                <span className="text-orange-400">✓</span>
                <span>Déploiement en 5 jours</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-orange-400">✓</span>
                <span>Sans engagement</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-orange-400">✓</span>
                <span>Support 24/7</span>
              </div>
            </div>
          </div>
        </Card>
      </div>
    </section>
  );
}
