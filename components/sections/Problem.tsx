'use client';

import { XCircle, Clock, TrendingDown } from 'lucide-react';

export default function Problem() {
  return (
    <section className="py-20 bg-gradient-to-b from-black to-red-950/10">
      <div className="max-w-6xl mx-auto px-4">
        {/* Header */}
        <div className="text-center mb-16">
          <h2 className="text-5xl font-bold text-red-400 mb-4">
            Vous générez des leads. Mais vous en perdez la moitié.
          </h2>
          <p className="text-xl text-gray-300">
            Chaque lead non traité = argent jeté par les fenêtres
          </p>
        </div>

        {/* 3 Pain Points */}
        <div className="grid md:grid-cols-3 gap-8 mb-12">
          <div className="bg-white/5 backdrop-blur-lg border border-red-500/20 rounded-2xl p-8 text-center">
            <div className="w-16 h-16 bg-red-500/10 rounded-full flex items-center justify-center mx-auto mb-4">
              <Clock className="w-8 h-8 text-red-400" />
            </div>
            <h3 className="text-2xl font-bold mb-3">Rappel trop tardif</h3>
            <p className="text-gray-400">
              Vos commerciaux rappellent 2h, 4h, parfois 24h après. Le lead est déjà passé chez le concurrent.
            </p>
          </div>

          <div className="bg-white/5 backdrop-blur-lg border border-red-500/20 rounded-2xl p-8 text-center">
            <div className="w-16 h-16 bg-red-500/10 rounded-full flex items-center justify-center mx-auto mb-4">
              <XCircle className="w-8 h-8 text-red-400" />
            </div>
            <h3 className="text-2xl font-bold mb-3">Relances oubliées</h3>
            <p className="text-gray-400">
              Les leads &quot;à recontacter plus tard&quot; tombent dans l&apos;oubli. Votre CRM devient un cimetière de prospects.
            </p>
          </div>

          <div className="bg-white/5 backdrop-blur-lg border border-red-500/20 rounded-2xl p-8 text-center">
            <div className="w-16 h-16 bg-red-500/10 rounded-full flex items-center justify-center mx-auto mb-4">
              <TrendingDown className="w-8 h-8 text-red-400" />
            </div>
            <h3 className="text-2xl font-bold mb-3">Temps perdu</h3>
            <p className="text-gray-400">
              Vos commerciaux passent 70% de leur temps à appeler des leads froids au lieu de closer des RDV.
            </p>
          </div>
        </div>

        {/* Stat choc */}
        <div className="bg-gradient-to-r from-red-950/40 to-red-900/20 backdrop-blur-lg border border-red-500/30 rounded-2xl p-10 text-center">
          <div className="text-6xl font-bold text-red-400 mb-3">87%</div>
          <p className="text-2xl text-gray-300 mb-2">
            des leads non contactés sous 5 minutes ne convertissent jamais.
          </p>
          <p className="text-gray-400 text-lg">
            Source : Harvard Business Review, 2023
          </p>
        </div>
      </div>
    </section>
  );
}
