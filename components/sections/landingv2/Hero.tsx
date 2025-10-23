'use client';

import Link from 'next/link';

export default function Hero() {
  return (
    <section className="relative py-24 overflow-hidden">
      {/* Gradient background */}
      <div className="absolute inset-0 bg-gradient-to-b from-violet-950/20 to-black pointer-events-none" />

      <div className="max-w-6xl mx-auto px-4 relative z-10">
        {/* Headline */}
        <div className="text-center mb-8">
          <h1 className="text-5xl md:text-6xl font-bold mb-6 leading-tight">
            Vos leads attendent des heures<br />avant d&apos;être rappelés.
            <span className="block mt-2 bg-gradient-to-r from-blue-500 to-violet-500 bg-clip-text text-transparent">
              VoIPIA les rappelle en 30 secondes.
            </span>
          </h1>

          <p className="text-xl md:text-2xl text-gray-300 max-w-4xl mx-auto leading-relaxed">
            Rappelez automatiquement vos leads, relancez vos bases inactives,<br />
            remplissez votre agenda et ne perdez plus jamais un prospect.<br />
            <span className="text-blue-400 font-semibold">Sans recruter. Déployé en 5 jours.</span>
          </p>
        </div>

        {/* Audio Demo Widget */}
        <div className="max-w-2xl mx-auto mb-8">
          <div className="bg-white/10 backdrop-blur-lg border border-white/20 rounded-2xl p-6">
            <div className="flex items-center gap-4 mb-4">
              <div className="text-4xl">🎧</div>
              <div>
                <div className="font-semibold text-lg">Écoutez Louis rappeler un lead</div>
                <div className="text-sm text-gray-400">Exemple : Lead immobilier (1:47)</div>
              </div>
            </div>
            <audio controls className="w-full">
              <source src="/demos/louis-demo.mp3" type="audio/mpeg" />
              Votre navigateur ne supporte pas l&apos;élément audio.
            </audio>
          </div>

          {/* Alternative : Numéro à appeler */}
          <div className="mt-4 text-center text-gray-400 text-sm">
            Ou appelez Louis maintenant :
            <a href="tel:+33XXXXXXXXX" className="ml-2 text-blue-400 hover:text-blue-300 font-semibold transition-colors">
              09 XX XX XX XX
            </a>
          </div>
        </div>

        {/* 3 Badges Métriques */}
        <div className="flex justify-center gap-8 md:gap-12 mb-12 flex-wrap">
          <div className="text-center">
            <div className="text-4xl font-bold text-blue-500 mb-1">89%</div>
            <div className="text-sm text-gray-400">Taux de réponse</div>
          </div>
          <div className="text-center">
            <div className="text-4xl font-bold text-violet-500 mb-1">+250%</div>
            <div className="text-sm text-gray-400">RDV posés</div>
          </div>
          <div className="text-center">
            <div className="text-4xl font-bold text-green-500 mb-1">18h</div>
            <div className="text-sm text-gray-400">Économisées/semaine</div>
          </div>
        </div>

        {/* CTAs */}
        <div className="flex flex-col sm:flex-row gap-4 justify-center mb-8">
          <Link
            href="#demo"
            className="px-8 py-4 bg-gradient-to-r from-blue-500 to-violet-500 rounded-xl font-bold text-lg hover:opacity-90 transition-opacity text-center"
          >
            ⚡ Je transforme mes leads en RDV
          </Link>
          <Link
            href="#roi-calculator"
            className="px-8 py-4 bg-white/10 border border-white/20 rounded-xl font-semibold text-lg hover:bg-white/20 transition-colors text-center"
          >
            Calculer mon ROI (30 sec)
          </Link>
        </div>

        {/* Micro-trust */}
        <div className="text-center text-gray-400 space-y-4">
          <div className="flex justify-center gap-6 flex-wrap text-sm">
            <span>✓ Essai 14 jours gratuit (sans CB)</span>
            <span>✓ Support français 24/7</span>
            <span>✓ Sans engagement</span>
          </div>

          {/* Avatars clients */}
          <div className="flex justify-center items-center gap-3">
            <div className="flex -space-x-4">
              {[1, 2, 3, 4, 5, 6, 7, 8].map((i) => (
                <div
                  key={i}
                  className="w-12 h-12 rounded-full border-2 border-black bg-gradient-to-br from-blue-500 to-violet-500"
                />
              ))}
            </div>
            <span className="text-sm">+200 entreprises font confiance à VoIPIA</span>
          </div>
        </div>
      </div>
    </section>
  );
}
